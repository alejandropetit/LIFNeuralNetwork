#!/usr/bin/env python
# license removed for brevity

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

