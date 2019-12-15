
import sys
import os
import multiprocessing
import select
import signal
import threading
import time
import logging

import serial

import derby


class SerialWorker(multiprocessing.Process):
    def __init__(self, pipe):
        multiprocessing.Process.__init__(self)
        self.pipe = pipe

    def run(self):
        # parent process will signal when this process should exit
        signal.signal(signal.SIGINT, signal.SIG_IGN)

        self._write_lock = threading.Lock()

        logging.info('Serial port: %s', derby.args.serial)

        try:
            self.serialPort = serial.Serial(derby.args.serial, derby.args.baud)
            self.serialPort.flushInput()
        except:
            raise derby.error('Unable to open serial port: %s', derby.args.serial) from None

        self.alive = True
        self.thread_read = threading.Thread(target=self.reader)
        self.thread_read.daemon = True
        self.thread_read.name = 'serial->pipe'
        self.thread_read.start()

        while self.alive:
            try:
                data = self.pipe.recv()
                if not data:
                    break
                self.serialPort.write(data)
            except Exception as e:
                print(e)
                # probably got disconnected
                break

        if self.alive:
            self.alive = False
            self.serialPort.close()
            self.thread_read.join()

    def reader(self):
        """loop forever and copy serial->pipe"""
        while self.alive:
            try:
                data = self.serialPort.read(self.serialPort.in_waiting or 1)
                if data:
                    self.write(data)
            except Exception as e:
                print(e)
                break

        self.alive = False
        logging.info('reader thread terminated')

    def write(self, data):
        """thread safe socket write with no data escaping. used to send telnet stuff"""
        with self._write_lock:
            self.pipe.send(data)

#        fds = [self.serialPort,self.pipe]
#        fds = [self.pipe]
#        while True:
#            ready = select.select(fds,[],[], 0.1)[0]
#            if not ready:
#                continue
#
#            fd = ready[0]
#            if fd == self.serialPort:
#                data = fd.read(self.serialPort.in_waiting)
#                self.pipe.send(data)
#            elif fd == self.pipe:
#                data = fd.recv()
#                if data == None:
#                    break
#                self.serialPort.write(data)
#                time.sleep(0.1)
#
#        self.serialPort.close()
