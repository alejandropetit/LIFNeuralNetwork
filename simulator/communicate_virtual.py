#!/usr/bin/env python
# license removed for brevity

import serial
import struct
import os

class SerialManager:

    MESSAGE_FORMAT = {
        0x01: {
            'keys': ['S1','S2','S3','S4','S5','S6','S7','S8'],
            'format': {
                'S1': ('<i', 2**6),
                'S2': ('<i', 2**6),
                'S3': ('<h', 2**14),
                'S4': ('<h', 2**14),
                'S5': ('<h', 1),
                'S6': ('<h', 1),
                'S7': ('<h', 1),
                'S8': ('<h', 1),
            }
        },

        0x02: {
            'keys': ['A1','A2','A3','A4'],
            'format': {
                'A1': ('<h', 1),
                'A2': ('<h', 1),
                'A3': ('<h', 1),
                'A4': ('<h', 1),
            }
        }
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
            message = self.MESSAGE_FORMAT[message_type]
            keys = message['keys']
            formats = message['format']
            payload = b''.join(struct.pack(formats[key][0], round(data[key]*formats[key][1])) for key in keys)
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

            if msg_type not in self.MESSAGE_FORMAT:
                return False, {}

            message = self.MESSAGE_FORMAT[msg_type]

            keys = message['keys']
            formats = message['format']

            length = sum(
                struct.calcsize(formats[key][0]) for key in keys
            )

            payload = self.connection.read(length)
            if len(payload) != length:
                return False, {}

            values = []
            offset = 0
            for key in keys:
                fmt, scale = formats[key]
                size = struct.calcsize(fmt)
                raw_value = struct.unpack_from(fmt, payload, offset)[0]
                value = raw_value / scale
                values.append(value)
                offset += size

            return True, dict(zip(keys, values))
        except (struct.error, serial.SerialException) as e:
            print("Error en lectura: {}".format(e))
            return False, {}