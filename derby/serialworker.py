
import sys
import os
import multiprocessing
import select
import signal
import time
import logging

import serial

import derby


class SerialWorker(multiprocessing.Process):
    def __init__(self, pipe):
        multiprocessing.Process.__init__(self)

        # parent process will signal when this process should exit
        signal.signal(signal.SIGINT, signal.SIG_IGN)

        self.pipe = pipe
        try:
            self.serialPort = serial.Serial(derby.args.serial, derby.args.baud)#, timeout=1)
            self.serialPort.flushInput()
        except:
            raise derby.error('Unable to open serial port: %s', derby.args.serial)

    def run(self):
        fds = [self.serialPort,self.pipe]
        while True:
            ready = select.select(fds,[],[], 0.2)[0]
            if not ready:
                continue

            fd = ready[0]
            if fd == self.serialPort:
                data = fd.read(self.serialPort.in_waiting)
                self.pipe.send(data)
            elif fd == self.pipe:
                data = fd.recv()
                if data == None:
                    break
                self.serialPort.write(data)

    def close(self):
        self.serialPort.close()

    def writeSerial(self, data):
        self.serialPort.write(data)
        # time.sleep(1)

    def readSerial(self):
        return self.serialPort.readline().decode('utf-8')
