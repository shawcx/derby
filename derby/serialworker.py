
import sys
import os
import multiprocessing
import select
import time
import logging

import serial

import derby


class SerialWorker(multiprocessing.Process):
    def __init__(self, input_queue, output_queue):
        multiprocessing.Process.__init__(self)
        self.shouldStop   = False
        self.input_queue  = input_queue
        self.output_queue = output_queue
        try:
            self.serialPort   = serial.Serial(derby.args.serial, derby.args.baud, timeout=1)
        except:
            raise derby.error('Unable to open serial port: %s', derby.args.serial)

    def close(self):
        self.serialPort.close()

    def writeSerial(self, data):
        self.serialPort.write(data)
        # time.sleep(1)

    def readSerial(self):
        return self.serialPort.readline().decode('utf-8')

    def run(self):
        self.serialPort.flushInput()

        try:
            while not self.shouldStop:
                time.sleep(0.1)
                #print('.')
                # look for incoming tornado request
                if not self.input_queue.empty():
                    data = self.input_queue.get()

                    # send it to the serial device
                    self.writeSerial(data)
                    logging.info("Writing to serial: %s", data)

                # look for incoming serial data
                if self.serialPort.in_waiting > 0:
                    data = self.readSerial()
                    logging.info("Reading from serial: %s", data)
                    # send it back to tornado
                    self.output_queue.put(data)

        except KeyboardInterrupt:
            pass
