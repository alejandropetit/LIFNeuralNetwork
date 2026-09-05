#!/usr/bin/env python
# license removed for brevity

import serial
import struct
import os

class SerialManager:

    ORDER_MAP = {
        0x01: (32, ['S1','S2','S3','S4','S5','S6','S7','S8']),
        0x02: (16, ['A1','A2','A3','A4'])
    }

    def __init__(self):
        self.connection = None

    def initialize(self, route, port, timeout, baudrate=115200):
        port_path = os.path.join(route, port)
        try:
            self.connection = serial.Serial(port_path,
                                            baudrate=baudrate,
                                            bytesize=serial.EIGHTBITS,
                                            parity=serial.PARITY_NONE,
                                            stopbits=serial.STOPBITS_ONE,
                                            timeout=timeout)
            return True
        except serial.SerialException as e:
            print("Error abriendo puerto serial {}: {}".format(port_path, e))
            return False

    def write_data(self, data, message_type):
        if not self.connection or not self.connection.is_open:
            return False
        try:
            keys = self.ORDER_MAP[message_type][1]
            payload = b''.join(struct.pack('<f', data[key]) for key in keys)
            header = struct.pack('<BB', 0xAA, message_type)

            self.connection.write(header + payload)
            return True
        except (KeyError, struct.error, serial.SerialException) as e:
            print("Error escribiendo datos: {}".format(e))
            return False

    def read_data(self):
        if not self.connection or not self.connection.is_open:
            return False, {}
        try:
            while True:
                byte = self.connection.read(1)
                if not byte:
                    return False, {}
                if byte == b'\xAA':
                    break

            type_byte = self.connection.read(1)

            if len(type_byte) != 1:
                return False, {}

            msg_type = struct.unpack('<B', type_byte)[0]                

            if msg_type not in self.ORDER_MAP:
                return False, {}

            length, keys = self.ORDER_MAP[msg_type]

            payload = self.connection.read(length)
            if len(payload) != length:
                return False, {}

            float_count = len(keys)
            values = struct.unpack('<{}f'.format(float_count), payload)

            return True, dict(zip(keys, values))
        except (struct.error, serial.SerialException) as e:
            print("Error en lectura: {}".format(e))
            return False, {}