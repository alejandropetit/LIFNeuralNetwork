#!/usr/bin/env python
# -*- coding: utf-8 -*-

import csv
import json
import math
import os
import sys
import time

import rospy
import tf
import communicate as cm

from std_msgs.msg import Float64
from snn_lockstep.srv import Step, StepRequest


# ============================================================
# CONFIGURATION
# ============================================================

SERIAL_DIRECTORY = '/dev'
SERIAL_PORT = 'ttyUSB0'
SERIAL_TIMEOUT = 15

DATA_DIRECTORY = (
    '/home/nelson/Documentos/Ubuntu_master/SNN_Codes/Spiking_codes'
)

ROUTES_DIRECTORY = '/home/nelson/Documentos/Ubuntu_master/routes'
ACTIVE_ROUTE = 'Test'

WAYPOINT_RADIUS = 2.0
START_YAW_DEG = 0.0

CONTROL_PERIOD = 1.0
INITIALIZATION_TIMEOUT = 150.0

save_data = True

CSV_COLUMNS = [
    'ID',
    'time',
    'x',
    'y',
    'speed',
    'pitch',
    'yaw',
    'relative_wind',
    'desired_heading',
    'apparent_wind',
    'waypoint_index',
    'waypoint_x',
    'waypoint_y',
    'waypoint_distance',
    'rudder_action',
    'sail_action'
]


# ============================================================
# ROUTE MANAGEMENT
# ============================================================

def is_finite(value):
    return not math.isnan(value) and not math.isinf(value)


def load_route():
    default_path = os.path.join(
        ROUTES_DIRECTORY,
        ACTIVE_ROUTE + '.json'
    )

    path = os.path.abspath(os.path.expanduser(
        os.environ.get('SNN_ROUTE_FILE', default_path)
    ))

    with open(path, 'r') as route_file:
        route = json.load(route_file)

    if not isinstance(route, list) or len(route) < 2:
        raise ValueError(
            'The route must contain at least two [x, y, type] points'
        )

    for index, waypoint in enumerate(route):
        if not isinstance(waypoint, list) or len(waypoint) != 3:
            raise ValueError(
                'Waypoint %d: expected [x, y, type]' % index
            )

        for value in waypoint:
            if (isinstance(value, bool) or
                    not isinstance(value, (int, float)) or
                    not is_finite(value)):
                raise ValueError(
                    'Waypoint %d: values must be finite numbers' % index
                )

        # The current FPGA protocol does not transmit waypoint types.
        if waypoint[2] != 0:
            raise ValueError(
                'Waypoint %d: the current FPGA controller '
                'only supports type 0' % index
            )

    rospy.loginfo('FPGA route: %s', path)
    return route


class RouteManager(object):
    def __init__(self, route, waypoint_radius):
        self.route = route
        self.waypoint_radius = waypoint_radius

        # Point 0 defines the initial position.
        # Point 1 is the first navigation target.
        self.index = 1
        self.finished = False

    def current_waypoint(self):
        return self.route[self.index]

    def update(self, x, y):
        if self.finished:
            return self.route[-1]

        waypoint = self.current_waypoint()
        distance = math.hypot(
            waypoint[0] - x,
            waypoint[1] - y
        )

        if distance < self.waypoint_radius:
            if self.index < len(self.route) - 1:
                self.index += 1
                waypoint = self.current_waypoint()

                rospy.loginfo(
                    'New waypoint %d/%d -> (%.2f, %.2f)',
                    self.index,
                    len(self.route) - 1,
                    waypoint[0],
                    waypoint[1]
                )
            else:
                self.finished = True

        return waypoint


# ============================================================
# ANGLES AND SENSOR PREPROCESSING
# ============================================================

def angle_saturation(angle):
    """Wrap an angle in degrees to [-180, 180)."""
    return (angle + 180.0) % 360.0 - 180.0


def desired_heading_to_waypoint(x, y, waypoint):
    dx = waypoint[0] - x
    dy = waypoint[1] - y

    return angle_saturation(
        math.degrees(math.atan2(dy, dx))
    )


def apparent_wind_angle(wind_x, wind_y, boat_vx_world, boat_vy_world):
    """Return the apparent wind direction in world coordinates."""
    apparent_x = wind_x - boat_vx_world
    apparent_y = wind_y - boat_vy_world

    return angle_saturation(
        math.degrees(math.atan2(apparent_y, apparent_x))
    )


def sensors_from_step(state, waypoint, wind_x, wind_y):
    q = state.pose.orientation
    quaternion = (q.x, q.y, q.z, q.w)

    _, pitch, yaw = tf.transformations.euler_from_quaternion(
        quaternion
    )

    pitch_deg = angle_saturation(math.degrees(pitch))
    yaw_deg = angle_saturation(math.degrees(yaw))

    # The step service returns velocities in the boat frame.
    velocity_body = [
        state.twist.linear.x,
        state.twist.linear.y,
        state.twist.linear.z
    ]

    # Convert velocity to the world frame used by the wind parameters.
    rotation = tf.transformations.quaternion_matrix(quaternion)
    velocity_world = rotation[:3, :3].dot(velocity_body)

    global_wind_deg = math.degrees(
        math.atan2(wind_y, wind_x)
    )

    sensors = {
        'S1': pitch_deg,
        'S2': yaw_deg,
        'S3': angle_saturation(global_wind_deg - yaw_deg),
        'S4': desired_heading_to_waypoint(
            state.pose.position.x,
            state.pose.position.y,
            waypoint
        ),
        'S5': apparent_wind_angle(
            wind_x,
            wind_y,
            velocity_world[0],
            velocity_world[1]
        ),
        'S6': math.hypot(
            velocity_body[0],
            velocity_body[1]
        )
    }

    if not all(is_finite(value) for value in sensors.values()):
        raise RuntimeError('Sensor values must be finite')

    return sensors


# ============================================================
# LOCKSTEP INITIALIZATION
# ============================================================

def initialize_from_route(route, yaw_deg=0.0):
    initial_x = float(route[0][0])
    initial_y = float(route[0][1])
    initial_yaw = math.radians(float(yaw_deg))

    for value in (initial_x, initial_y, initial_yaw):
        if not is_finite(value):
            raise ValueError('Initial pose must contain finite values')

    rospy.wait_for_service(
        '/snn_step/advance',
        timeout=INITIALIZATION_TIMEOUT
    )

    for name in ('sail_joint', 'sail_joint_2'):
        rospy.wait_for_service(
            '/snn_step/' + name,
            timeout=INITIALIZATION_TIMEOUT
        )

    # Plugins load concurrently. Wait for the joint PID configuration.
    deadline = time.time() + INITIALIZATION_TIMEOUT

    while True:
        if rospy.is_shutdown():
            raise RuntimeError('Initialization interrupted')

        config = rospy.get_param(
            '/sailboat/controllers/config/joints',
            {}
        )
        names = config.get('name', [])

        if (2 <= len(names) <= 3 and
                all(len(config.get(key, [])) == len(names)
                    for key in ('lower', 'upper', 'velocity'))):
            break

        if time.time() > deadline:
            raise RuntimeError(
                'Joint PID initialization did not complete'
            )

        # Sleep in wall time: the simulation clock remains at zero.
        time.sleep(0.02)

    advance = rospy.ServiceProxy('/snn_step/advance', Step)

    state = advance(StepRequest(
        sequence=0,
        initialize=True,
        steps=0,
        initial_x=initial_x,
        initial_y=initial_y,
        initial_yaw=initial_yaw
    ))

    if not state.success:
        raise RuntimeError(state.status_message)

    if (state.sequence != 0 or
            state.iteration != 0 or
            state.sim_time.to_sec() != 0.0):
        raise RuntimeError(
            'Trial did not start at time zero and iteration zero'
        )

    x = state.pose.position.x
    y = state.pose.position.y

    if (not is_finite(x) or not is_finite(y) or
            math.hypot(x - initial_x, y - initial_y) > 1e-6):
        raise RuntimeError(
            'Initial position does not match the route'
        )

    rospy.loginfo(
        'FPGA lockstep initialized: x=%.3f, y=%.3f, yaw=%.3f deg',
        initial_x,
        initial_y,
        yaw_deg
    )

    return advance, state


def get_steps_per_control(state):
    step_size = state.step_size

    if not is_finite(step_size) or step_size <= 0.0:
        raise RuntimeError('Invalid physics step size')

    steps = int(round(CONTROL_PERIOD / step_size))

    if (steps <= 0 or steps > 100000 or
            abs(steps * step_size - CONTROL_PERIOD) > 1e-9):
        raise RuntimeError(
            'Physics step size must divide the control period '
            'within the step service limits'
        )

    return steps


# ============================================================
# FPGA COMMUNICATION
# ============================================================

def request_action(serial_mgr, sensors):
    if not serial_mgr.write_data(sensors, message_type=0x01):
        raise RuntimeError('Cannot send sensors to the FPGA')

    success, action = serial_mgr.read_data()

    if not success or set(action) != set(('A1', 'A2')):
        raise RuntimeError('Incomplete or invalid FPGA response')

    rudder_deg = float(action['A1'])
    sail_deg = float(action['A2'])

    for value, limit in (
            (rudder_deg, 45.0),
            (sail_deg, 90.0)):
        if not is_finite(value) or abs(value) > limit:
            raise RuntimeError(
                'FPGA action is outside the allowed range'
            )

    rospy.loginfo(
        'RX FPGA: rudder=%.2f deg, sail=%.2f deg',
        rudder_deg,
        sail_deg
    )

    return rudder_deg, sail_deg


# ============================================================
# TELEMETRY
# ============================================================

def create_publishers():
    names = (
        'move_usv/result',
        'currentHeading',
        'windDirection',
        'heeling',
        'spHeading',
        'waypoint_distance',
        'waypoint_index'
    )

    return {
        name: rospy.Publisher(name, Float64, queue_size=10)
        for name in names
    }


def publish_telemetry(
        publishers, sensors, route_manager, distance,
        wind_x, wind_y):
    global_wind_deg = math.degrees(
        math.atan2(wind_y, wind_x)
    )

    values = {
        'move_usv/result': 1.0 if route_manager.finished else 0.0,
        'currentHeading': math.radians(-sensors['S2']),
        'windDirection': math.radians(
            angle_saturation(sensors['S3'] + 180.0)
        ),
        'heeling': angle_saturation(global_wind_deg + 180.0),
        'spHeading': sensors['S4'],
        'waypoint_distance': distance,
        'waypoint_index': float(route_manager.index)
    }

    for name, value in values.items():
        publishers[name].publish(Float64(data=value))


# ============================================================
# CSV RECORDING
# ============================================================

def create_output(file_name):
    if not save_data:
        return None, None

    directory = os.path.join(DATA_DIRECTORY, 'data_result')

    if not os.path.isdir(directory):
        os.makedirs(directory)

    path = os.path.join(directory, file_name + '.csv')

    # Python 2 csv requires binary mode.
    # Python 3 csv requires newline='' to manage line endings.
    if sys.version_info[0] == 2:
        stream = open(path, 'wb')
    else:
        stream = open(path, 'w', newline='')

    try:
        writer = csv.DictWriter(
            stream,
            fieldnames=CSV_COLUMNS,
            lineterminator='\n'
        )
        writer.writeheader()
        stream.flush()
    except Exception:
        stream.close()
        raise

    rospy.loginfo('FPGA results: %s', path)
    return stream, writer


def record_sample(
        stream, writer, sample_id, state, sensors,
        route_manager, waypoint, distance, rudder_deg, sail_deg):
    if writer is None:
        return

    writer.writerow({
        'ID': sample_id,
        'time': state.sim_time.to_sec(),
        'x': state.pose.position.x,
        'y': state.pose.position.y,
        'speed': sensors['S6'],
        'pitch': sensors['S1'],
        'yaw': sensors['S2'],
        'relative_wind': sensors['S3'],
        'desired_heading': sensors['S4'],
        'apparent_wind': sensors['S5'],
        'waypoint_index': route_manager.index,
        'waypoint_x': waypoint[0],
        'waypoint_y': waypoint[1],
        'waypoint_distance': distance,
        'rudder_action': rudder_deg,
        'sail_action': sail_deg
    })

    # Make each completed row available to the trial supervisor.
    stream.flush()


# ============================================================
# LOCKSTEP CONTROL LOOP
# ============================================================

def run_loop(
        advance, state, steps_per_control, serial_mgr,
        route_manager, publishers, stream, writer, wind_x, wind_y):
    sample_id = 1

    while not rospy.is_shutdown():
        x = state.pose.position.x
        y = state.pose.position.y

        if not is_finite(x) or not is_finite(y):
            raise RuntimeError('Boat position must be finite')

        waypoint = route_manager.update(x, y)

        distance = math.hypot(
            waypoint[0] - x,
            waypoint[1] - y
        )

        sensors = sensors_from_step(
            state,
            waypoint,
            wind_x,
            wind_y
        )

        elapsed = state.sim_time.to_sec()

        # No new action is requested after reaching the final waypoint.
        rudder_deg = ''
        sail_deg = ''

        if not route_manager.finished:
            rudder_deg, sail_deg = request_action(
                serial_mgr,
                sensors
            )
            
            if elapsed <= 4.0:
                yaw_q = round(sensors['S2'] * 128) / 128.0
                apparent_q = round(sensors['S5'] * 128) / 128.0

                sum_angle_q = angle_saturation(
                    apparent_q + yaw_q
                )
                sail_index = int(
                    (36 * (sum_angle_q + 180.0)) // 360
                )

                rospy.loginfo(
                    'SAIL_DEBUG FPGA t=%.0f yaw=%.9f '
                    'sum_angle=%.9f index=%d action=%s',
                    elapsed,
                    yaw_q,
                    sum_angle_q,
                    sail_index,
                    sail_deg
                )            

        # Each normal row records the action for the following interval.
        # The final row has empty action fields because no step follows.
        record_sample(
            stream,
            writer,
            sample_id,
            state,
            sensors,
            route_manager,
            waypoint,
            distance,
            rudder_deg,
            sail_deg
        )
        sample_id += 1

        publish_telemetry(
            publishers,
            sensors,
            route_manager,
            distance,
            wind_x,
            wind_y
        )

        if route_manager.finished:
            # Preserve the message expected by the existing trial runner.
            rospy.loginfo(
                'RUTA COMPLETADA FPGA: %.3f segundos simulados',
                elapsed
            )
            return

        if rospy.is_shutdown():
            return

        next_sequence = state.sequence + 1

        # Do not retry: a lost response may follow a completed step.
        next_state = advance(StepRequest(
            sequence=next_sequence,
            initialize=False,
            steps=steps_per_control,
            rudder=math.radians(rudder_deg),
            sail=math.radians(sail_deg),
            sail2=math.radians(sail_deg)
        ))

        if not next_state.success:
            raise RuntimeError(next_state.status_message)

        if next_state.sequence != next_sequence:
            raise RuntimeError('Physics step sequence mismatch')

        if next_state.iteration != state.iteration + steps_per_control:
            raise RuntimeError('Unexpected physics iteration count')

        time_increment = next_state.sim_time.to_sec() - elapsed

        if abs(time_increment - CONTROL_PERIOD) > 1e-8:
            raise RuntimeError('Unexpected simulated time increment')

        state = next_state


# ============================================================
# MAIN
# ============================================================

def main():
    rospy.init_node('usv_simple_ctrl', anonymous=True)

    route = load_route()
    route_manager = RouteManager(route, WAYPOINT_RADIUS)

    advance, state = initialize_from_route(
        route,
        yaw_deg=START_YAW_DEG
    )

    steps_per_control = get_steps_per_control(state)

    # Keep the wind configuration fixed throughout this trial.
    wind_x = float(rospy.get_param('/uwsim/wind/x'))
    wind_y = float(rospy.get_param('/uwsim/wind/y'))

    if not is_finite(wind_x) or not is_finite(wind_y):
        raise ValueError('Wind components must be finite')

    publishers = create_publishers()
    serial_mgr = cm.SerialManager()

    stream, writer = create_output(file_name='Test_FPGA')

    try:
        # The FPGA must already have been reset before this trial.
        if not serial_mgr.initialize(
                SERIAL_DIRECTORY,
                SERIAL_PORT,
                SERIAL_TIMEOUT):
            raise RuntimeError('Cannot open the FPGA serial port')

        run_loop(
            advance,
            state,
            steps_per_control,
            serial_mgr,
            route_manager,
            publishers,
            stream,
            writer,
            wind_x,
            wind_y
        )

    finally:
        try:
            serial_mgr.invalidate_connection()
        finally:
            if stream is not None:
                stream.close()


if __name__ == '__main__':
    try:
        main()
    except rospy.ROSInterruptException:
        pass
    except Exception as exc:
        rospy.logerr('FPGA lockstep trial failed: %s', str(exc))
        raise