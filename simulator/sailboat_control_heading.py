#!/usr/bin/python
from __future__ import print_function
import csv
import ctypes
import datetime
import json
import math
import os
import sys
import time

import rospy
from tf.transformations import euler_from_quaternion
from snn_lockstep.srv import Step, StepRequest

INSTALLED = '/home/nelson/catkin_ws/install_isolated/share/usv_base_ctrl/scripts'
sys.path.insert(0, INSTALLED)
import communicate as cm

RUN = None
NETWORK = '/home/nelson/Documentos/Ubuntu_master/SNN_Codes/Spiking_codes'
DEFAULT_ROUTE = '/home/nelson/Documentos/Ubuntu_master/routes/route.json'


class Timespec(ctypes.Structure):
    _fields_ = [('seconds', ctypes.c_long), ('nanoseconds', ctypes.c_long)]


clock_gettime = (None if hasattr(time, 'monotonic') else
                 ctypes.CDLL('librt.so.1', use_errno=True).clock_gettime)


def monotonic():
    if hasattr(time, 'monotonic'):
        return time.monotonic()
    value = Timespec()
    if clock_gettime(1, ctypes.byref(value)):
        raise OSError(ctypes.get_errno(), 'clock_gettime failed')
    return value.seconds + value.nanoseconds * 1e-9


def save(name, data):
    if RUN is None:
        return
    path = os.path.join(RUN, name)
    with open(path + '.tmp', 'w') as stream:
        json.dump(data, stream)
    getattr(os, 'replace', os.rename)(path + '.tmp', path)


def load_route(path):
    with open(path, 'r') as stream:
        route = json.load(stream)
    if not isinstance(route, list) or len(route) < 2:
        raise ValueError('route.json must contain at least two [x, y, type] points')
    for point in route:
        if not isinstance(point, list) or len(point) != 3:
            raise ValueError('Each route point must be [x, y, type]')
        for value in point:
            if (isinstance(value, bool) or not isinstance(value, (int, float))
                    or math.isnan(value) or math.isinf(value)):
                raise ValueError('Route coordinates and types must be finite numbers')
    return route
    
def initialize_from_route(route, yaw_deg=0.0):
    initial_x = float(route[0][0])
    initial_y = float(route[0][1])
    initial_yaw = math.radians(float(yaw_deg))

    for value in (initial_x, initial_y, initial_yaw):
        if math.isnan(value) or math.isinf(value):
            raise ValueError('Initial pose must contain finite values')

    rospy.wait_for_service('/snn_step/advance', timeout=150)

    for name in ('sail_joint', 'sail_joint_2'):
        rospy.wait_for_service('/snn_step/' + name, timeout=150)

    # Plugins load concurrently. Wait for the joint PID configuration.
    deadline = time.time() + 150.0
    while True:
        if rospy.is_shutdown():
            raise RuntimeError('Initialization interrupted')

        config = rospy.get_param('/sailboat/controllers/config/joints', {})
        names = config.get('name', [])

        if (2 <= len(names) <= 3 and
                all(len(config.get(key, [])) == len(names)
                    for key in ('lower', 'upper', 'velocity'))):
            break

        if time.time() > deadline:
            raise RuntimeError('Joint PID initialization did not complete')

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

    if (state.sequence != 0 or state.iteration != 0 or
            state.sim_time.to_sec() != 0.0):
        raise RuntimeError('Trial did not start at time zero and iteration zero')

    if math.hypot(state.pose.position.x - initial_x,
                  state.pose.position.y - initial_y) > 1e-6:
        raise RuntimeError('Initial position does not match the route')

    return advance, state

def read_action(port, first_sample):
    success, action = port.read_data()
    # The original test_SNN sends a startup reset before answering sensors.
    # Consume it once; do not resend sensors or advance physics for this message.
    if success and action.get('A4') == 1000 and first_sample:
        success, action = port.read_data()
    if not success:
        raise RuntimeError('Cannot receive the SNN action')
    if not all(key in action for key in ('A1', 'A2', 'A3', 'A4')):
        raise RuntimeError('Invalid SNN action message')
    if action['A4'] not in (0, 1, 3, -1):
        raise RuntimeError('Unexpected SNN status/reset: ' + str(action['A4']))
    return action


class RouteProgress(object):
    def __init__(self, route):
        self.route = route
        self.target_index = 1  # First point is the start, not a target.
        self.completed = False

    def update(self, action, sensors):
        if self.completed:
            raise RuntimeError('Received an action after route completion')
        target_index = self.target_index
        target = self.route[target_index]
        # Compare the same quantized position sent through the serial protocol.
        x = int(round(sensors['S1'] * 64)) / 64.0
        y = int(round(sensors['S2'] * 64)) / 64.0
        distance = math.hypot(target[0] - x, target[1] - y)
        if action['A4'] in (1, -1):
            if distance > 2.0 + 1e-9:
                raise RuntimeError('SNN arrival disagrees with route.json; check both routes')
            last = target_index == len(self.route) - 1
            if action['A4'] == -1 and not last:
                raise RuntimeError('SNN ended before the last route.json target')
            self.completed = last
            if not last:
                self.target_index += 1
        return target_index


def angle_saturation(value):
    if value > 180:
        value -= 360
    if value < -180:
        value += 360
    return value


def sensors_from_state(state, wind_direction):
    q = state.pose.orientation
    roll, pitch, yaw = euler_from_quaternion((q.x, q.y, q.z, q.w))
    heading = -angle_saturation(math.degrees(yaw))
    relative_wind = angle_saturation(math.degrees(wind_direction) + heading)
    return {'S1': state.pose.position.x, 'S2': state.pose.position.y,
            'S3': state.twist.linear.x, 'S4': state.twist.linear.y,
            'S5': round(math.degrees(roll), 0), 'S6': round(math.degrees(pitch), 0),
            'S7': round(-heading, 0), 'S8': round(relative_wind, 0)}


def main():
    global RUN
    rospy.init_node('usv_simple_ctrl', anonymous=True)
    route_path = os.path.abspath(os.path.expanduser(
        os.environ.get('SNN_ROUTE_FILE', DEFAULT_ROUTE)))
    route = load_route(route_path)
    tracker = RouteProgress(route)
    output_default = os.path.join(os.path.dirname(os.path.dirname(NETWORK)),
        'results', 'lockstep', datetime.datetime.now().strftime('%Y%m%d_%H%M%S_%f')
        + '_' + str(os.getpid()))
    RUN = os.path.abspath(os.path.expanduser(os.environ.get('SNN_RUN_DIR', output_default)))
    if not os.path.isdir(RUN):
        os.makedirs(RUN)
    max_sim = float(os.environ.get('SNN_MAX_SIM', '3600'))
    if math.isnan(max_sim) or math.isinf(max_sim) or max_sim <= 0:
        raise ValueError('SNN_MAX_SIM must be positive and finite')
    serial_timeout = float(os.environ.get('SNN_SERIAL_TIMEOUT', '150'))
    if math.isnan(serial_timeout) or math.isinf(serial_timeout) or serial_timeout <= 0:
        raise ValueError('SNN_SERIAL_TIMEOUT must be positive and finite')
    save('route_used.json', route)
    save('route_used.json', route)
    rospy.loginfo('Lockstep route: %s; results: %s', route_path, RUN)

    advance, state = initialize_from_route(route, yaw_deg=0.0)

    steps_per_control = int(round(1.0 / state.step_size))
    if steps_per_control <= 0 or abs(steps_per_control * state.step_size - 1.0) > 1e-9:
        raise RuntimeError('Physics step must divide the 1 Hz SNN period')

    wind = math.atan2(rospy.get_param('/uwsim/wind/y'),rospy.get_param('/uwsim/wind/x'))
    port = cm.SerialManager()
    deadline = monotonic() + 150
    while not os.path.exists(os.path.join(NETWORK, 'interface_2')):
        if monotonic() > deadline or rospy.is_shutdown():
            raise RuntimeError('Virtual serial port interface_2 was not created')
        time.sleep(0.02)
    if not port.initialize(NETWORK, 'interface_2', timeout=serial_timeout):
        raise RuntimeError('Cannot open the SNN virtual serial port')

    try:
        run_loop(advance, state, steps_per_control, wind, port, route, tracker, max_sim)
    finally:
        port.connection.close()


def run_loop(advance, state, steps_per_control, wind, port, route, tracker, max_sim):
    if sys.version_info[0] == 2:
        stream = open(os.path.join(RUN, 'Test_Python.csv'), 'wb')
    else:
        stream = open(os.path.join(RUN, 'Test_Python.csv'), 'w', newline='')
    columns = ['ID', 'time', 'x', 'y', 'speed', 'pitch', 'yaw', 'relative_wind',
               'waypoint_index', 'waypoint_x', 'waypoint_y', 'waypoint_distance',
               'rudder_action', 'sail_action', 'sensor_x', 'sensor_y',
               'response_sim_time', 'roundtrip_wall_seconds', 'processing_wall_seconds', 'iteration']
    writer = csv.DictWriter(stream, columns)
    writer.writeheader()
    began = monotonic()
    start_time = state.sim_time.to_sec()
    sample = 0
    try:
        while not rospy.is_shutdown():
            sensors = sensors_from_state(state, wind)
            sent = monotonic()
            if not port.write_data(sensors, message_type=0x01):
                raise RuntimeError('Cannot send sensors to the SNN')
            action = read_action(port, first_sample=(sample == 0))
            received = monotonic()
            sample += 1
            target_index = tracker.update(action, sensors)
            target = route[target_index]
            elapsed = state.sim_time.to_sec() - start_time
            row = dict(ID=sample, time=elapsed, x=sensors['S1'], y=sensors['S2'],
                       speed=math.hypot(sensors['S3'], sensors['S4']), pitch=sensors['S6'],
                       yaw=sensors['S7'], relative_wind=sensors['S8'],
                       waypoint_index=target_index, waypoint_x=target[0], waypoint_y=target[1],
                       waypoint_distance=math.hypot(target[0]-sensors['S1'], target[1]-sensors['S2']),
                       rudder_action=action['A1'], sail_action=action['A2'],
                       sensor_x=sensors['S1'], sensor_y=sensors['S2'], response_sim_time=elapsed,
                       roundtrip_wall_seconds=received-sent, processing_wall_seconds='',
                       iteration=state.iteration)
            writer.writerow(row)
            stream.flush()
            progress = dict(simulation_seconds=elapsed, wall_seconds=received-began,
                            samples=sample, waypoint_index=target_index)
            save('progress.json', progress)
            if tracker.completed:
                save('navigation.json', dict(progress, outcome='completed'))
                return
            if elapsed >= max_sim:
                save('navigation.json', dict(progress, outcome='simulation_timeout'))
                return
            next_state = advance(StepRequest(sequence=sample, initialize=False, steps=steps_per_control,
                rudder=math.radians(action['A1']), sail=math.radians(action['A2']), sail2=math.radians(action['A3'])))
            if not next_state.success:
                raise RuntimeError(next_state.status_message)
            if next_state.sequence != sample or next_state.iteration != state.iteration + steps_per_control:
                raise RuntimeError('Physics step sequence mismatch')
            if abs(next_state.sim_time.to_sec() - state.sim_time.to_sec() - 1.0) > 1e-8:
                raise RuntimeError('Unexpected simulated time increment')
            state = next_state
        save('navigation.json', {'outcome': 'interrupted', 'samples': sample})
    finally:
        stream.close()


if __name__ == '__main__':
    try:
        main()
    except Exception as exc:
        save('navigation.json', {'outcome': 'failed', 'error': str(exc)})
        raise
