#!/usr/bin/env python3

import argparse
import collections
import configparser
import json
import logging
import multiprocessing
import os
import platform
import queue
import signal
import socket
import sys

import serial
import tornado.web
import tornado.ioloop


ioloop = tornado.ioloop.IOLoop.instance()

defaultSerials = {
    #'Linux'   : '/dev/ttyUSB0',
    'Linux'   : '/dev/ttyDERBY',
    'Darwin'  : '/dev/cu.usbserial',
    'Windows' : 'COM3',
}

# parse the command line arguments
argparser = argparse.ArgumentParser()

argparser.add_argument('--serial',
    metavar='<tty>', default=defaultSerials.get(platform.system()),
    help='serial port to open'
    )

argparser.add_argument('--baud',
    metavar='<speed>', type=int, default=9600,
    help='serial port speed'
    )

argparser.add_argument('--addr',
    metavar='<ip>', default='0.0.0.0',
    help='address to listen on'
    )

argparser.add_argument('--port',
    metavar='<port>', type=int, default=8000,
    help='port to bind to'
    )

argparser.add_argument('--debug',
    action='store_true',
    help='enable debug options'
    )

args = argparser.parse_args()

# Setting default stdout logging
logging.basicConfig(
    format  = '%(asctime)s %(levelname)-8s %(message)s',
    datefmt = '%Y-%m-%d %H:%M:%S',
    level   = logging.DEBUG if args.debug else logging.INFO
    )


class Template(tornado.web.RequestHandler):
    def get(self, template=None):
        template = template+'.html' if template else 'index.html'
        self.render(template)



class Application(tornado.web.Application):
    def __init__(self):
        self.websockets = {}

        self.serialPort = serial.Serial(args.serial, args.baud)
        ioloop.add_handler(self.serialPort, self.tapReadCb, ioloop.READ)

        ## periodically check the serial pipe for data
        #self.scheduler = tornado.ioloop.PeriodicCallback(self.trackState.readSerialPort, 50)
        #self.scheduler.start()

        patterns = [
            #( r'/racers/([0-9]*)', derby.handlers.Racers    ),
            #( r'/times/([0-9]*)',  derby.handlers.Times     ),
            #( r'/serial',          derby.handlers.Serial    ),
            #( r'/ws',              derby.handlers.WebSocket ),
            ( r'/',                Template  ),
            ]

        # Tornado settings
        self.settings = dict(
            debug         = args.debug,
            autoreload    = False,
            )

        super(Application, self).__init__(patterns, **self.settings)

        try:
            self.listen(args.port, args.addr, xheaders=True)
        except Exception as e:
            raise

        logging.info('Listening on %s:%d', args.addr, args.port)

        signal.signal(signal.SIGINT,  self.SignalHandler)
        signal.signal(signal.SIGTERM, self.SignalHandler)

        ioloop.start()
        logging.info('Good-Bye')

    def tapReadCb(self, fd, event):
        data = fd.read(fd.in_waiting)
        print(data.decode('utf-8').strip())

    def Broadcast(self, action, message):
        'Broadcast a message to all connected sockets'
        bundle = {
            'action'  : action,
            'message' : message,
            }
        for websocket in self.websockets.values():
            websocket.write_message(bundle)

    def Stop(self):
        #self.scheduler.stop()
        ioloop.add_callback_from_signal(ioloop.stop)
        #self.localPipe.send(None)

    def SignalHandler(self, signum, frame):
        print()
        logging.info('Terminating')
        self.Stop()


if '__main__' == __name__:
    try:
        Application()
    except derby.error as e:
        logging.error('%s', e)
        sys.exit(-1)
