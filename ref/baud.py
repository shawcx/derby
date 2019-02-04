#!/usr/bin/env python3

import sys
import os
import select

import serial

ser = serial.Serial('/dev/ttyUSB0', 9600)
print(ser.name)

d = b''
try:
    while True:
        results = select.select([ser,sys.stdin],[],[], 0.1)
        if not results[0]:
            #print('.')
            continue

        #print(results[0])
        if results[0][0] == ser:
            d += ser.read()
            if d.endswith(b'\n'):
                print(d.decode('utf-8')[:-1])
                d = b''
            continue
        else:
            buff = sys.stdin.readline()
            ser.write(buff.encode('utf-8'))
            continue
except KeyboardInterrupt:
    ser.close()
