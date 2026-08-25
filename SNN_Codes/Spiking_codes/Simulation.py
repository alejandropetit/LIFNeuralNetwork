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

        band, data = self.manager.read_data()
        print("SUCCESS:", band)
        print("DATA:", data)

        if band:
            position = [data['S1'], data['S2']]
            angles = [data['S5'], data['S6'], data['S7']]
            wind = data['S8']
            speed = [data['S3'], data['S4']]

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
                

