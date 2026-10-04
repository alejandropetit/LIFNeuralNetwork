#!/usr/bin/env python
# license removed for brevity

import serial
import struct
import os

class SerialManager:

    MESSAGE_FORMAT = {
        0x01: {
            'keys': ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'],
            'format': '<8f'
        },
        0x02: {
            'keys': ['A1', 'A2', 'A3', 'A4'],
            'format': '<4f'
        }
    }

    def __init__(self):
        self.connection = None

    def initialize(self, route, port, timeout, baudrate=9600):
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
            values = [float(data[key]) for key in message['keys']]

            payload = struct.pack(message['format'], *values)
            header = struct.pack('<BB', 0xAA, message_type)
            packet = header + payload

            return self.connection.write(packet) == len(packet)

        except (
            KeyError, TypeError, ValueError, OverflowError,
            struct.error, serial.SerialException
        ) as e:
            print("Error writing data: {}".format(e))
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

            message_type = struct.unpack('<B', type_byte)[0]
            if message_type not in self.MESSAGE_FORMAT:
                return False, {}

            message = self.MESSAGE_FORMAT[message_type]
            length = struct.calcsize(message['format'])

            payload = self.connection.read(length)
            if len(payload) != length:
                return False, {}

            values = struct.unpack(message['format'], payload)
            return True, dict(zip(message['keys'], values))

        except (struct.error, serial.SerialException) as e:
            print("Error reading data: {}".format(e))
            return False, {}