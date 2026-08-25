import communicate as cm

class SerialPort:
    def __init__(self, direction: str, port_name: str, timeout: float):
        self.direction = direction
        self.port_name = port_name
        self.timeout = timeout
        self.is_open = False

        self.manager = cm.SerialManager()

    def open_port(self) -> bool:
        self.is_open = self.manager.initialize(self.direction, self.port_name, self.timeout)

        if self.is_open:
            print(f"Puerto {self.port_name} abierto correctamente.")
        else:
            print(f"Error: El puerto {self.port_name} no pudo ser abierto.")

        return self.is_open

    def read_data_sensor(self):
        if not self.is_open:
            return False

        band, recibe = self.manager.read_data()
        print("BAND:", band)
        print("RECIBE:", recibe)

        if band and recibe:
            position = [recibe.get('S1', 0), recibe.get('S2', 0)]
            angles = [recibe.get('S5', 0), recibe.get('S6', 0), recibe.get('S7', 0)]
            wind = recibe.get('S8', 0)
            speed = [recibe.get('S3', 0), recibe.get('S4', 0)]

            return [True] + position + angles + [wind] + speed
        return False
    
    def write_control_action(self, control_action: list) -> bool:
        if not self.is_open or len(control_action) < 4:
            return False

        datos = {
            'A1' : control_action[0],
            'A2' : control_action[1],
            'A3' : control_action[2],
            'A4' : control_action[3],
        }

        order = ['A1', 'A2', 'A3', 'A4']

        return self.manager.write_data(datos, order, message_type=0x02)
































import original_controller as ctr

class serial_port:
    direction=''
    port_name=''
    timeout=0
    j = False
    
    def __init__(self, direct, port, time):
        self.direction = direct
        self.port_name = port
        self.timeout = time
        
    def read_data_sensor(self):
        band = False
        [band,recibe] = cm.read_data()
        print("BAND:", band)
        print("RECIBE:", recibe)
        if band and self.j:
            position =  [recibe['S1'],recibe['S2']]
            angles = [recibe['S5'],recibe['S6'],recibe['S7']]
            wind = recibe['S8']
            speed = [recibe['S3'],recibe['S4']]
            band = [band]+position+angles+[wind]+speed

        return band
    
    def read_data_sensor_2(self):
        band = False
        [band,recibe] = cm.read_data()
        if band and self.j:
            position =  [recibe['S1'],recibe['S2'],recibe['S3'],recibe['S4']]
            angles = [recibe['S5'],recibe['S6'],recibe['S7']]
            wind = recibe['S8']
            band = [band]+[position]+[angles]+[wind]

        return band

    def write_control_action(self,control_action):
        band=False
        if self.j:
            datos={'A1' : control_action[0], 'A2' : control_action[1], 
                   'A3' : control_action[2], 'A4' : control_action[3]}
            order = ['A1', 'A2', 'A3', 'A4']
            band=cm.write_data(datos, order, 2)

        return band

    def classic_control_action(self,data,info=1000):
        if info==1000:
            rudder_angle = ctr.rudder_ctrl(data[1],data[2])
            sail_angle = ctr.sail_ctrl(data[3]+data[2][2])
        else:
            rudder_angle = info
            sail_angle = ctr.sail_ctrl(data)
        result = ctr.verify_result()
        return [rudder_angle,sail_angle,sail_angle,result]

    def open_port(self):
        l=cm.serial_initialization(self.direction,self.port_name,self.timeout)
        if not l:
            print('El puerto no pudo ser abierto')
        else:
            print("Puerto abierto correctamente")
        self.j=l
        return l

    def classic_controller(self):
        while self.j:
            data=self.read_data_sensor_2()
            if not isinstance(data,bool):
                control = self.classic_control_action(data)
                self.write_control_action(control)
            else:
                print("No hay dato")
                

