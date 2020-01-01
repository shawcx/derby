#!/usr/bin/env python3

import sys
import os
import select

import serial

class VirtualTrack:
    def __init__(self):
        self.serialPort = serial.Serial('/dev/ttyTRACK')

        while True:
            fds = select.select([self.serialPort,sys.stdin],[],[],1.0)
            rfds = fds[0]
            if not rfds:
                continue
            if rfds[0] == self.serialPort:
                d = self.serialPort.read(self.serialPort.in_waiting)
                print(d)
            else:
                d = sys.stdin.readline()
                d = d.encode('utf-8')
                self.serialPort.write(d)


if '__main__' == __name__:
    VirtualTrack()
