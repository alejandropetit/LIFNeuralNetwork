#!/usr/bin/env python
# license removed for brevity

import rospy
import math
import tf
import communicate as cm
import text_file as db
import SNNexperiment as SN
from sensor_msgs.msg import JointState
from std_msgs.msg import Header
from nav_msgs.msg import Odometry
from geometry_msgs.msg import Quaternion
from geometry_msgs.msg import Twist, Point, Quaternion
from std_msgs.msg import Float64
from std_srvs.srv import Empty
from gazebo_msgs.msg import ModelState 
from gazebo_msgs.srv import SetModelState
from tf.transformations import quaternion_from_euler


permutation = 923
direction = '/home/nelson/Documentos/Ubuntu_master/SNN_Codes/Spiking_codes'

serial_mgr = cm.SerialManager()

experiment = SN.SNNexperiment()

# Generar la ruta de prueba
experiment.train_scenario(test=True)
experiment.reset_route()

# Dataset
experiment.set_database( db_name='Test_' + str(permutation), path=direction,structure=['ID','state','wind','x','y','speed','heeling','rudder','sail'])

initial_pose = Odometry()
target_pose = Odometry()
rate_value = 2   # Period of saving data
control_rate = 1 # Period of the controller (1/control_time)
result = Float64()
result.data = 0
windDir= Float64()
windDir.data = 1.5 
currentHeading= Float64()
currentHeading.data = 0
current_heading = 0
heeling = 0
spHeading = 10 
isTacking = 0
reset_world = 0
save_data = False
counter = 0
time_counter = 0
base = ''
db_name = 'Test_1'
constant = [2,3]
state_msg = ''
yaw_angles = [0,135,179,0] #Train yaw angles
yaw_counter = 0

def get_pose(initial_pose_tmp):
    global initial_pose 
    initial_pose = initial_pose_tmp

def get_target(target_pose_tmp):
    global target_pose 
    target_pose = target_pose_tmp
    
def angle_saturation(sensor):
    if sensor > 180:
        sensor = sensor - 360
    if sensor < -180:
        sensor = sensor + 360
    return sensor

def talker_ctrl():
    global rate_value
    global currentHeading
    global windDir 
    global isTacking
    global heeling
    global spHeading
    global counter
    global time_counter
    global base 
    global constant

    rospy.init_node('usv_simple_ctrl', anonymous=True)
    rate = rospy.Rate(rate_value) # 0.5Hz
    # publishes to thruster and rudder topics
    pub_sail = rospy.Publisher('/sail/angleLimits', Float64, queue_size=10)
    #pub_sail_2 = rospy.Publisher('sail_2/angleLimits', Float64, queue_size=10)
    pub_rudder = rospy.Publisher('joint_setpoint', JointState, queue_size=10)
    pub_result = rospy.Publisher('move_usv/result', Float64, queue_size=10)
    pub_heading = rospy.Publisher('currentHeading', Float64, queue_size=10)
    pub_windDir = rospy.Publisher('windDirection', Float64, queue_size=10)
    pub_heeling = rospy.Publisher('heeling', Float64, queue_size=10)
    pub_spHeading = rospy.Publisher('spHeading', Float64, queue_size=10)
    
    # subscribe to state and targer point topics
    rospy.Subscriber("state", Odometry, get_pose)  # get usv position (add 'gps' position latter)
    rospy.Subscriber("move_usv/goal", Odometry, get_target)  # get target position


    while not rospy.is_shutdown():
        try:
	        time_counter += (1.0/rate_value)
	        if save_data and constant[0]!=constant[1]:
                base = db.text_files(new_file = True, file_name = db_name, structure = ['time','speed','wind','x','y'])  
		        constant[0] = constant[1]
		        time_counter = 0
	        final = rudder_ctrl_msg()
	        if not save_data or counter >= (rate_value // control_rate):
                pub_rudder.publish(final[0])
	            pub_sail.publish(final[1])
		        counter = 0
                #pub_sail_2.publish(final[2])
            pub_result.publish(result)
            pub_heading.publish(currentHeading)
            pub_windDir.publish(windDir)
            pub_heeling.publish(heeling)
            pub_spHeading.publish(spHeading)
            rate.sleep()
        except rospy.ROSInterruptException:
	        rospy.logerr("ROS Interrupt Exception! Just ignore the exception!")
        except rospy.ROSTimeMovedBackwardsException:
	        rospy.logerr("ROS Time Backwards! Just ignore the exception!")

def reset_environment(yaw):
    q = quaternion_from_euler(0, 0, yaw)
    state_msg.model_name = 'sailboat'
    state_msg.pose.position.x = 240
    state_msg.pose.position.y = 100
    state_msg.pose.position.z = 0
    state_msg.pose.orientation.x = q[0]
    state_msg.pose.orientation.y = q[1]
    state_msg.pose.orientation.z = q[2]
    state_msg.pose.orientation.w = q[3]
    resp = set_state(state_msg)

def controller():
    # erro = sp - atual
    # ver qual gira no horario ou anti-horario
    # aciona o motor (por enquanto valor fixo)
    global initial_pose
    global target_pose
    global current_heading
    global currentHeading
    global spHeading
    global windDir
    global heeling
    global result
    global base
    global counter
    global time_counter
    global constant
    global db_name
    global yaw_counter
	
    port_name='/dev/ttyUSB0'
    direction= '/home/nelson/Documentos/Ubuntu_master/SNN_Codes/Spiking_codes'
    timeout=15

    if not serial_mgr.connection or not serial_mgr.connection.is_open:
        if not serial_mgr.initialize(direction, port_name, timeout):
            rospy.logerr("No se pudo abrir el puerto serial.")
            return 0, 0, 0


    rudder_angle=0
    sail_angle = 1
    sail_angle_2 = 1
    result_py3=0
    # Position(set up and GPS) and odometry sensors processing and aconditioning

    x1 = initial_pose.pose.pose.position.x
    y1 = initial_pose.pose.pose.position.y
    x2 = initial_pose.twist.twist.linear.x
    y2 = initial_pose.twist.twist.linear.y
    speed = math.sqrt(x2**2+y2**2)####nuevo cambio
    quaternion = (initial_pose.pose.pose.orientation.x, initial_pose.pose.pose.orientation.y, initial_pose.pose.pose.orientation.z,initial_pose.pose.pose.orientation.w) 
    euler = tf.transformations.euler_from_quaternion(quaternion)

    target_angle = math.degrees(euler[2])
    myradians = math.atan2(y2-y1,x2-x1)
    sp_angle = math.degrees(myradians)
    sp_angle = angle_saturation(sp_angle)
    spHeading = sp_angle
    target_angle = angle_saturation(target_angle)
    target_angle = -target_angle
    current_heading = math.radians(target_angle)
    currentHeading.data = current_heading
    ###############################################


    ##############################################
    # Wind sensor processing and aconditionating
    x = rospy.get_param('/uwsim/wind/x')
    y = rospy.get_param('/uwsim/wind/y')
    global_dir = math.atan2(y,x)
    heeling = angle_saturation(math.degrees(global_dir)+180)
    wind_dir = global_dir + current_heading
    wind_dir = angle_saturation(math.degrees(wind_dir))
    windDir.data = math.radians(angle_saturation(math.degrees(wind_dir)+180))
    #############################################
    counter += 1

    if save_data:
        base.append_data([time_counter,speed,math.degrees(global_dir),x1,y1])

    # =========================================================
    # Ejecutar controlador según control_rate
    # =========================================================
    if not save_data or counter >= (rate_value // control_rate):

        try:
            # =================================================
            # Sensores
            # =================================================
            info = []

            info.append(round(math.degrees(euler[0]), 0))          # roll
            info.append(round(math.degrees(euler[1]), 0))          # pitch
            info.append(round(math.degrees(-current_heading), 0))  # yaw
            info.append(round(wind_dir, 0))                        # viento relativo


             # =================================================
             # Actualizar ruta
             # =================================================
            route_status = experiment.update_route(x1, y1)


             # =================================================
             # Fin de recorrido
             # =================================================
            if route_status == experiment.ROUTE_FINISHED:

                rospy.loginfo("Recorrido finalizado")

                rudder_angle = 0
                sail_angle = 0
                sail_angle_2 = 0

                result.data = experiment.ROUTE_FINISHED

                return (
                     math.radians(rudder_angle),
                     math.radians(sail_angle),
                     math.radians(sail_angle_2)
                 )


             # =================================================
             # Waypoint activo
             # =================================================
            desired_heading = experiment.desired_heading_cal(x1,y1)

            next_waypoint_value = (
                experiment.waypoints[
                experiment.state + 1
                ][2]
            )


             # =================================================
             # Viento
             # =================================================
            real_wind_angle = experiment.angle_saturation(
                ang=info[3] + info[2],
                min_ang=-180,
                max_ang=180
            )

            aparent_wind = experiment.aparent_wind_calc(
                real_wind_angle=real_wind_angle,
                sailboat_speed=speed,
                yaw=info[2]
            )


             # =================================================
             # Paquete FPGA
             # =================================================
            datos = {
            'S1': info[0],               # roll / heeling
            'S2': info[2],               # yaw
            'S3': info[3],               # viento relativo
            'S4': desired_heading,
            'S5': aparent_wind,
            'S6': speed,
            'S7': next_waypoint_value
            }


             # =================================================
             # Enviar a FPGA
             # =================================================
            if not serial_mgr.write_data(datos,message_type=0x01):
                rospy.logerr(
                    "No se pudo escribir en el puerto"
                )

            else:
                band, recibe = serial_mgr.read_data()

                if band:
                    rudder_angle = recibe['A1']
                    sail_angle = recibe['A2']

                    # Si ambas velas usan la misma salida
                    sail_angle_2 = sail_angle


                    # =========================================
                    # Guardar paso
                    # =========================================
                    experiment.process_step(
                        x=x1,
                        y=y1,
                        speed=speed,
                        heeling=info[0],
                        real_wind_angle=real_wind_angle,
                        control_action=(rudder_angle,sail_angle)
                    )

        except Exception as e:
            rospy.logerr(
                "Error en controlador/serial: %s",
                str(e)
            )


        # =====================================================
        # Salidas
        # =====================================================
        return (
            math.radians(rudder_angle),
            math.radians(sail_angle),
            math.radians(sail_angle_2)
        )

    else:
        return 0, 0, 0

def rudder_ctrl_msg():
    msg = JointState()
    msg.header = Header()
    msg.name = ['rudder_joint', 'sail_joint', 'sail_joint_2']
    res = controller()
    msg.position = [res[0], res[1], res[2]]
    msg.velocity = []
    msg.effort = []
    return msg,res[1],res[2]

if __name__ == '__main__':

    global reset_world
    global control_rate
    global rate_value

    #rospy.wait_for_service('/gazebo/reset_world')
    #reset_world = rospy.ServiceProxy('/gazebo/reset_world', Empty)

    state_msg = ModelState()
    rospy.wait_for_service('/gazebo/set_model_state')
    set_state = rospy.ServiceProxy('/gazebo/set_model_state', SetModelState)
    reset_environment(math.radians(yaw_angles[yaw_counter]))

    if not save_data:
	    rate_value = control_rate
    try:
        talker_ctrl()
    except rospy.ROSInterruptException:
        pass
