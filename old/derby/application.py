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

import tornado.web
import tornado.ioloop

import derby

ioloop = tornado.ioloop.IOLoop.instance()

defaultSerials = {
    'Linux'   : '/dev/ttyUSB0',
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

argparser.add_argument('--db',
    metavar='<sqlite db>', default='derby.sqlite',
    help='Path to database'
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

derby.args = argparser.parse_args()

# Setting default stdout logging
logging.basicConfig(
    format  = '%(asctime)s %(levelname)-8s %(message)s',
    datefmt = '%Y-%m-%d %H:%M:%S',
    level   = logging.DEBUG if derby.args.debug else logging.INFO
    )


class Application(tornado.web.Application):
    def __init__(self, localPipe):
        derby.db = derby.Database(derby.args.db)

        derby.app = self

        self.localPipe = localPipe

        self.websockets = {}

        # class to manage the state of the track
        self.trackState = derby.TrackState(self.localPipe)

        # periodically check the serial pipe for data
        self.scheduler = tornado.ioloop.PeriodicCallback(self.trackState.readSerialPort, 50)
        self.scheduler.start()

        patterns = [
            ( r'/racers/([0-9]*)', derby.handlers.Racers    ),
            ( r'/times/([0-9]*)',  derby.handlers.Times     ),
            ( r'/serial',          derby.handlers.Serial    ),
            ( r'/ws',              derby.handlers.WebSocket ),
            ( r'/',                derby.handlers.Template  ),
            ]

        # Tornado settings
        self.settings = dict(
            static_path   = os.path.join(derby.root, 'static'),
            template_path = os.path.join(derby.root, 'templates'),
            debug         = derby.args.debug,
            autoreload    = False,
            pipe          = self.localPipe,
            )

        super(Application, self).__init__(patterns, **self.settings)

        try:
            self.listen(derby.args.port, derby.args.addr, xheaders=True)
        except Exception as e:
            raise derby.error('Could not listen: %s' % e)

        logging.info('Listening on %s:%d', derby.args.addr, derby.args.port)

        signal.signal(signal.SIGINT,  self.SignalHandler)
        signal.signal(signal.SIGTERM, self.SignalHandler)

        ioloop.start()
        logging.info('Exiting')

    def Broadcast(self, action, message):
        'Broadcast a message to all connected sockets'
        bundle = {
            'action'  : action,
            'message' : message,
            }
        for websocket in self.websockets.values():
            websocket.write_message(bundle)

    def Stop(self):
        self.scheduler.stop()
        ioloop.add_callback_from_signal(ioloop.stop)
        self.localPipe.send(None)

    def SignalHandler(self, signum, frame):
        print()
        logging.info('Terminating')
        self.Stop()


if '__main__' == __name__:
    multiprocessing.freeze_support()
    try:
        Application()
    except derby.error as e:
        logging.error('%s', e)
        sys.exit(-1)
