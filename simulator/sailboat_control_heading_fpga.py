#!/usr/bin/env python
# -*- coding: utf-8 -*-

import rospy
import math
import tf
import communicate as cm
import text_file as db
import os
import json

from sensor_msgs.msg import JointState
from std_msgs.msg import Header, Float64
from nav_msgs.msg import Odometry
from gazebo_msgs.msg import ModelState
from gazebo_msgs.srv import SetModelState
from tf.transformations import quaternion_from_euler


# ============================================================
# CONFIGURACION GENERAL
# ============================================================

SERIAL_DIRECTORY = '/dev'
SERIAL_PORT = 'ttyUSB0'
SERIAL_TIMEOUT = 15

DATA_DIRECTORY = '/home/nelson/Documentos/Ubuntu_master/SNN_Codes/Spiking_codes'

rate_value = 2       # Frecuencia del loop cuando se guardan datos
control_rate = 1     # Frecuencia del controlador
save_data = True


ROUTES_DIRECTORY = '/home/nelson/Documentos/Ubuntu_master/routes'

ACTIVE_ROUTE = 'Test'


#ACTIVE_ROUTE = 'test'
WAYPOINT_RADIUS = 2.0
START_YAW_DEG = 0.0


# ============================================================
# ESTADO GLOBAL ROS / SERIAL
# ============================================================

serial_mgr = cm.SerialManager()
initial_pose = Odometry()
state_msg = ModelState()
set_state = None

currentHeading = Float64()
windDir = Float64()
spHeading = Float64()
result = Float64()
heeling = 0.0

waypointDistance = Float64()
waypointIndex = Float64()
last_rudder_action_deg = 0.0
last_sail_action_deg = 0.0

counter = 0
time_counter = 0.0
base = None


# ============================================================
# MANEJO INTERNO DE LA RUTA
# ============================================================

class RouteManager(object):
    def __init__(self, route, waypoint_radius):
        if len(route) < 2:
            raise ValueError('La ruta debe tener al menos dos waypoints')

        self.route = route
        self.waypoint_radius = waypoint_radius
        # El waypoint 0 es el punto inicial; navegamos hacia el 1.
        self.index = 1
        self.finished = False

    def current_waypoint(self):
        return self.route[self.index]

    def update(self, x, y):
        """
        Revisa si el velero alcanzo el waypoint actual.
        Si lo alcanzo, selecciona automaticamente el siguiente.

        Retorna:
            waypoint actual [x, y, waypoint_type]
        """
        if self.finished:
            return self.route[-1]

        wp = self.current_waypoint()
        distance = math.hypot(wp[0] - x, wp[1] - y)

        if distance <= self.waypoint_radius:
            if self.index < len(self.route) - 1:
                self.index += 1
                wp = self.current_waypoint()
                rospy.loginfo(
                    'Nuevo waypoint %d/%d -> (%.2f, %.2f), type=%d',
                    self.index,
                    len(self.route) - 1,
                    wp[0],
                    wp[1],
                    int(wp[2])
                )
            else:
                self.finished = True
                rospy.loginfo('Ruta terminada.')

        return wp


def load_route(route_name):
    path = os.path.join(ROUTES_DIRECTORY, route_name + '.json')

    with open(path, 'r') as route_file:
        route = json.load(route_file)

    if not isinstance(route, list) or len(route) < 2:
        raise ValueError('La ruta debe tener al menos dos waypoints')

    for index, waypoint in enumerate(route):
        if not isinstance(waypoint, list) or len(waypoint) != 3:
            raise ValueError(
                'Waypoint %d: se esperaba [x, y, waypoint_type]' % index
            )

        x, y, waypoint_type = waypoint
        if any(
            isinstance(value, bool)
            or not isinstance(value, (int, float))
            or math.isnan(value)
            or math.isinf(value)
            for value in waypoint
        ):
            raise ValueError(
                'Waypoint %d: los valores deben ser numeros finitos' % index
            )

        if int(waypoint_type) != waypoint_type:
            raise ValueError(
                'Waypoint %d: waypoint_type debe ser entero' % index
            )

    return route


route_manager = RouteManager(
    load_route(ACTIVE_ROUTE),
    WAYPOINT_RADIUS
)


# ============================================================
# FUNCIONES AUXILIARES
# ============================================================

def get_pose(initial_pose_tmp):
    global initial_pose
    initial_pose = initial_pose_tmp


def angle_saturation(angle):
    """Satura un angulo en grados al rango [-180, 180)."""
    while angle >= 180.0:
        angle -= 360.0
    while angle < -180.0:
        angle += 360.0
    return angle


def desired_heading_to_waypoint(x, y, waypoint):
    """Heading geometrico desde la posicion actual hacia el waypoint."""
    dx = waypoint[0] - x
    dy = waypoint[1] - y
    return angle_saturation(math.degrees(math.atan2(dy, dx)))


def apparent_wind_angle(wind_x, wind_y, boat_vx_world, boat_vy_world):
    """Viento aparente en coordenadas globales, expresado en grados."""
    apparent_x = wind_x - boat_vx_world
    apparent_y = wind_y - boat_vy_world

    return angle_saturation(
        math.degrees(math.atan2(apparent_y, apparent_x))
    )


def reset_environment(yaw_rad):
    global state_msg
    global set_state

    q = quaternion_from_euler(0, 0, yaw_rad)
    initial = route_manager.route[0]

    state_msg.model_name = 'sailboat'
    state_msg.pose.position.x = initial[0]
    state_msg.pose.position.y = initial[1]
    state_msg.pose.position.z = 0
    state_msg.pose.orientation.x = q[0]
    state_msg.pose.orientation.y = q[1]
    state_msg.pose.orientation.z = q[2]
    state_msg.pose.orientation.w = q[3]

    set_state(state_msg)


# ============================================================
# CONTROL + UART
# ============================================================

def controller():
    global counter
    global time_counter
    global currentHeading
    global windDir
    global spHeading
    global result
    global heeling
    global base
    global last_rudder_action_deg
    global last_sail_action_deg
    global waypointDistance
    global waypointIndex

    # --------------------------------------------------------
    # 1. Abrir UART una sola vez
    # --------------------------------------------------------
    if not serial_mgr.connection or not serial_mgr.connection.is_open:
        if not serial_mgr.initialize(SERIAL_DIRECTORY, SERIAL_PORT, SERIAL_TIMEOUT):
            rospy.logerr('No se pudo abrir el puerto serial.')
            counter = 0
            return 0.0, 0.0

    # --------------------------------------------------------
    # 2. Leer estado del velero desde ROS
    # --------------------------------------------------------
    x_pos = initial_pose.pose.pose.position.x
    y_pos = initial_pose.pose.pose.position.y
    vx = initial_pose.twist.twist.linear.x
    vy = initial_pose.twist.twist.linear.y

    quaternion = (
        initial_pose.pose.pose.orientation.x,
        initial_pose.pose.pose.orientation.y,
        initial_pose.pose.pose.orientation.z,
        initial_pose.pose.pose.orientation.w
    )
    euler = tf.transformations.euler_from_quaternion(quaternion)

    roll_deg = angle_saturation(math.degrees(euler[0]))
    pitch_deg = angle_saturation(math.degrees(euler[1]))
    yaw_deg = angle_saturation(math.degrees(euler[2]))

    # Se conserva el signo usado por el visualizador/control antiguo.
    currentHeading.data = math.radians(-yaw_deg)

    # --------------------------------------------------------
    # 3. Ruta interna: waypoint actual y siguiente waypoint
    # --------------------------------------------------------
    waypoint = route_manager.update(x_pos, y_pos)

    distance = math.hypot(waypoint[0] - x_pos, waypoint[1] - y_pos)

    waypointDistance.data = distance
    waypointIndex.data = route_manager.index

    if route_manager.finished:

        counter = 0
        result.data = 1
        return 0.0, 0.0

    desired_heading_deg = desired_heading_to_waypoint(x_pos, y_pos, waypoint)
    waypoint_type = int(waypoint[2])
    spHeading.data = desired_heading_deg

    # --------------------------------------------------------
    # 4. Viento y velocidad
    # --------------------------------------------------------
    wind_x = rospy.get_param('/uwsim/wind/x')
    wind_y = rospy.get_param('/uwsim/wind/y')

    global_wind_deg = angle_saturation(math.degrees(math.atan2(wind_y, wind_x)))

    # Viento relativo al heading del velero.
    relative_wind_deg = angle_saturation(global_wind_deg - yaw_deg)

    speed = math.sqrt(vx * vx + vy * vy)

    # El tópico state entrega velocidad en los ejes del barco.
    velocity_body = [
        initial_pose.twist.twist.linear.x,
        initial_pose.twist.twist.linear.y,
        initial_pose.twist.twist.linear.z,
    ]

    # Transformarla a los mismos ejes globales usados por el viento.
    rotation = tf.transformations.quaternion_matrix(quaternion)
    velocity_world = rotation[:3, :3].dot(velocity_body)

    apparent_wind_deg = apparent_wind_angle(
        wind_x,
        wind_y,
        velocity_world[0],
        velocity_world[1]
    )

    heeling = angle_saturation(global_wind_deg + 180.0)
    windDir.data = math.radians(angle_saturation(relative_wind_deg + 180.0))

    # --------------------------------------------------------
    # 5. Guardado opcional
    # --------------------------------------------------------
    counter += 1
    time_counter += 1.0 / rate_value

    if save_data and base is not None:
        base.append_data([time_counter,x_pos,y_pos,speed,pitch_deg,yaw_deg,relative_wind_deg,desired_heading_deg,apparent_wind_deg,route_manager.index,waypoint[0],waypoint[1],distance,last_rudder_action_deg,last_sail_action_deg])

    # --------------------------------------------------------
    # 6. Enviar EXACTAMENTE 7 valores a la FPGA
    # --------------------------------------------------------
    if not save_data or counter >= (rate_value // control_rate):
        counter = 0

        datos = {
            'S1': pitch_deg,
            'S2': yaw_deg,
            'S3': relative_wind_deg,
            'S4': desired_heading_deg,
            'S5': apparent_wind_deg,
            'S6': speed,
            'S7': waypoint_type,
        }

        rospy.loginfo(
            'TX FPGA: pitch=%.2f yaw=%.2f relWind=%.4f desired=%.4f appWind=%.2f speed=%.3f wp=%d',
            datos['S1'],
            datos['S2'],
            datos['S3'],
            datos['S4'],
            datos['S5'],
            datos['S6'],
            datos['S7']
        )

        try:
            if not serial_mgr.write_data(datos, message_type=0x01):
                rospy.logwarn('No se pudo escribir en el puerto serial.')
                return 0.0, 0.0

            band, recibe = serial_mgr.read_data()


            rospy.loginfo('RX FPGA: band=%s data=%s',band,str(recibe))

            # ------------------------------------------------
            # 7. Recibir SOLO 2 valores desde la FPGA
            # ------------------------------------------------
            if not band:
                rospy.logwarn('No se recibio una respuesta valida de la FPGA.')
                return 0.0, 0.0

            rudder_angle_deg = recibe['A1']
            sail_angle_deg = recibe['A2']

            last_rudder_action_deg = rudder_angle_deg
            last_sail_action_deg = sail_angle_deg


            result.data = 0
            counter = 0

            return (
                math.radians(rudder_angle_deg),
                math.radians(sail_angle_deg)
            )

        except Exception as exc:
            rospy.logerr('Error de comunicacion con la FPGA: %s', str(exc))
            return 0.0, 0.0

    return 0.0, 0.0


# ============================================================
# MENSAJES ROS
# ============================================================

def rudder_ctrl_msg():
    rudder_angle, sail_angle = controller()

    msg = JointState()
    msg.header = Header()

    # La FPGA retorna un solo angulo de vela. Si el modelo tiene dos
    # articulaciones de vela, ambas reciben el mismo valor.
    msg.name = ['rudder_joint', 'sail_joint', 'sail_joint_2']
    msg.position = [rudder_angle, sail_angle, sail_angle]
    msg.velocity = []
    msg.effort = []

    return msg, sail_angle


def talker_ctrl():
    global rate_value
    global counter
    global base

    rate = rospy.Rate(rate_value)

    pub_sail = rospy.Publisher('/sail/angleLimits', Float64, queue_size=10)
    pub_rudder = rospy.Publisher('joint_setpoint', JointState, queue_size=10)
    pub_result = rospy.Publisher('move_usv/result', Float64, queue_size=10)
    pub_heading = rospy.Publisher('currentHeading', Float64, queue_size=10)
    pub_windDir = rospy.Publisher('windDirection', Float64, queue_size=10)
    pub_heeling = rospy.Publisher('heeling', Float64, queue_size=10)
    pub_spHeading = rospy.Publisher('spHeading', Float64, queue_size=10)
    pub_wp_distance = rospy.Publisher('waypoint_distance', Float64, queue_size=10)
    pub_wp_index = rospy.Publisher('waypoint_index', Float64, queue_size=10)

    # Ya no existe move_usv/goal: la ruta es interna.
    rospy.Subscriber('state', Odometry, get_pose)

    if save_data:
        base = db.text_files(
            new_file=True,
            file_name='Test_FPGA',
            path=DATA_DIRECTORY,
            structure=['time','x','y','speed','pitch','yaw','relative_wind','desired_heading','apparent_wind','waypoint_index','waypoint_x','waypoint_y','waypoint_distance','rudder_action','sail_action']
        )

    while not rospy.is_shutdown():
        try:
            final = rudder_ctrl_msg()

            if not save_data or counter == 0:
                pub_rudder.publish(final[0])
                pub_sail.publish(final[1])

            pub_result.publish(result)
            pub_heading.publish(currentHeading)
            pub_windDir.publish(windDir)
            pub_heeling.publish(heeling)
            pub_spHeading.publish(spHeading)
            pub_wp_distance.publish(waypointDistance)
            pub_wp_index.publish(waypointIndex)

            rate.sleep()

        except rospy.ROSInterruptException:
            rospy.logerr('ROS Interrupt Exception!')
        except rospy.ROSTimeMovedBackwardsException:
            rospy.logerr('ROS Time Backwards!')


# ============================================================
# MAIN
# ============================================================

if __name__ == '__main__':
    rospy.init_node('usv_simple_ctrl', anonymous=True)

    state_msg = ModelState()

    rospy.wait_for_service('/gazebo/set_model_state')
    set_state = rospy.ServiceProxy('/gazebo/set_model_state', SetModelState)

    reset_environment(math.radians(START_YAW_DEG))

    if not save_data:
        rate_value = control_rate

    try:
        talker_ctrl()
    except rospy.ROSInterruptException:
        pass
