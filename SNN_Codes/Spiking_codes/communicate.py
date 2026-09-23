
import serial
import struct

serial_name = '/'


# Absolute route of the port, name of port, side of communication, timeout of readline
def serial_initialization(route, port, times):
    lecture = True
    try:
        global serial_name
        serial_name = serial.Serial(route + '/' + port, timeout=times)
    except:
        lecture = False
    return lecture


def write_data(data, order, message_type):
    write_correct = True
    data_send = b''
    global serial_name
    try: 
        for key in order: data_send += struct.pack('<f', data[key])
        packet = struct.pack('<BBB', 0xAA, message_type, len(data_send))
        packet += data_send

        serial_name.write(packet)
    except:
        write_correct = False
    return write_correct


def read_data():
    global serial_name

    try:
        header = serial_name.read(3)

        if len(header) != 3:
import os
from typing import Tuple, Dict, Any, Optional

class SerialManager:

    ORDER_MAP = {
        0x01: (32, ['S1','S2','S3','S4','S5','S6','S7','S8']),
        0x02: (16, ['A1','A2','A3','A4'])
    }

    def __init__(self):
        self.connection: Optional[serial.Serial] = None

    def initialize(self, route: str, port: str, timeout: float) -> bool:
        port_path = os.path.join(route, port)
        try:
            self.connection = serial.Serial(port_path, timeout=timeout)
            return True
        except serial.SerialException as e:
            print(f"Error abriendo puerto serial {port_path}: {e}")
            return False

    def write_data(self, data: Dict[str, float], order: list, message_type: int) -> bool:
        if not self.connection or not self.connection.is_open:
            return False
        try:
            payload = b''.join(struct.pack('<f', data[key]) for key in order)
            header = struct.pack('<BBB', 0xAA, message_type, len(payload))

            self.connection.write(header + payload)
            return True
        except (KeyError, struct.error, serial.SerialException) as e:
            print(f"Error escribiendo datos: {e}")
            return False

    def read_data(self) -> Tuple[bool, Dict[str, float]]:
        if not self.connection or not self.connection.is_open:
            return False, {}
        
        packet_header, message_type, data_length = struct.unpack('<BBB', header)

        if packet_header != 0xAA:
            return False, {}

        if message_type == 0x01 and data_length != 32:
            return False, {}

        if message_type == 0x02 and data_length != 16:
            return False, {}

        data = serial_name.read(data_length)
        
        if len(data) != data_length:
            return False, {}

        data = data_format(data, message_type)

        return True, data
    except:
        return False, {}


def data_format(data_read, message_type):
    data = {}

    if message_type == 0x01:
        order = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8']
    elif message_type == 0x02:
        order = ['A1', 'A2', 'A3', 'A4']
    else:
        return {}

    for i, key in enumerate(order):
        start = i * 4
        value = struct.unpack('<f', data_read[start:start + 4])[0]
        data[key] = value

    return data
        try:
            while True:
                byte = self.connection.read(1)
                if not byte:
                    return False, {}
                if byte[0] == 0xAA:
                    break
            metadata = self.connection.read(2)
            if len(metadata) < 2:
                return False, {}

            msg_type, length = struct.unpack('<BB', metadata)

            if msg_type not in self.ORDER_MAP:
                return False, {}

            expected_length, keys = self.ORDER_MAP[msg_type]
            if length != expected_length:
                return False, {}

            payload = self.connection.read(length)
            if len(payload) != length:
                return False, {}

            float_count = len(keys)
            values = struct.unpack(f'<{float_count}', payload)

            return True, dict(zip(keys, values))
        except (struct.error, serial.SerialException) as e:
                    print(f"Error en lectura: {e}")
                    return False, {}