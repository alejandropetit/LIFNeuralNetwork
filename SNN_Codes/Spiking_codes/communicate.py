#!/usr/bin/env python
# license removed for brevity

import serial

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


def write_data(data, order):
    write_correct = True
    data_send = ''
    global serial_name
    try:
        for key in order: data_send = data_send + key + 'x' + str(data[key]) + 'x'
        data_send = data_send + '\n'
        serial_name.write(data_send.encode('utf-8'))
    except:
        write_correct = False
    return write_correct


def read_data():
    global serial_name
    try:
        data = serial_name.readline().decode('utf-8')
        print("RAW DATA:", repr(data))
        if data == '': return False, {} 
        data = data_format(data[:-1])
        return True, data
    except:
        return False, {}


def data_format(data_read):
    data = {}
    d2 = data_read.split('x')
    for i in range(len(d2)):
        if i % 2 != 0: data[d2[i - 1]] = float(d2[i])
    return data
