#!/usr/bin/env python3

import sys
import os
import select
import cmd
import threading

import serial

class SerialThread(threading.Thread):
    def run(self):
        pass

class Derby(cmd.Cmd):
    prompt = 'Derby > '

    def preloop(self):
        #self.m = 'Matt'
        try:
            self.serialfp = serial.Serial('/dev/ttyUSB0', 9600)
        except:
            raise derby.error('Could not open serial port')

#        d = b''
#        try:
#            while True:
#                results = select.select([ser,sys.stdin],[],[], 0.1)
#                if not results[0]:
#                    #print('.')
#                    continue
#
#                #print(results[0])
#                if results[0][0] == ser:
#                    d += ser.read()
#                    if d.endswith(b'\n'):
#                        print(d.decode('utf-8')[:-1])
#                        d = b''
#                    continue
#                else:
#                    buff = sys.stdin.readline()
#                    ser.write(buff.encode('utf-8'))
#                    continue

    def send(self, command):
        command = command.encode('ascii')
        self.serialfp.write(command)

    def receive(self):
        data = self.serialfp.readline()
        data = data.decode('ascii')
        data = data.strip()
        data = data.replace('@', '')
        data = data.replace('>', '')
        return data

    def postloop(self):
        self.serialfp.close()

    def precmd(self, line):
        return line

    #def postcmd(self, stop, line):
    #    if not stop:
    #        try:
    #            while True:
    #                d = self.serialfp.read()
    #                sys.stdout.buffer.write(d)
    #                sys.stdout.buffer.flush()
    #        except KeyboardInterrupt:
    #            print()
    #    return True if stop is True else False

    def do_init(self, line):
        self.send('RV')

    def do_check(self, line):
        self.send('RG')
        status = self.receive()
        print('>>>', status )

    def do_go(self, line):
        # check if the gate is closed
        self.send('RG')
        self.send('LG')
        command = self.receive()
        status  = self.receive()
        if command[-1] == '0':
            print('Switch not closed')
            return
        try:
            times = self.receive()
            print('Times:', times)
        except KeyboardInterrupt:
            print()
            print('Race cancelled')


    def do_EOF(self, line):
        return True


if '__main__' == __name__:
    derby = Derby()
    try:
        derby.cmdloop()
    except KeyboardInterrupt:
        derby.postloop()
