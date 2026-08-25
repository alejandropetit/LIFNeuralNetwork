#!/usr/bin/env python
# license removed for brevity

import serial
import struct
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