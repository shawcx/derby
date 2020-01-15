#!/usr/bin/env python3

import argparse
import collections
import configparser
import json
import logging
import os
import platform
import queue
import signal
import socket
import sys

import serial
import tornado.web
import tornado.ioloop

import derby


ioloop = tornado.ioloop.IOLoop.instance()


def main():
    # parse the command line arguments
    argparser = argparse.ArgumentParser()

    argparser.add_argument('--baud',
        metavar='<speed>', type=int, default=9600,
        help='serial port speed'
        )

    argparser.add_argument('--db',
        metavar='<sqlite db>', default=os.path.join(derby.root, 'derby.sqlite'),
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

    try:
        Application()
    except derby.error as e:
        logging.error('%s', e)
        sys.exit(-1)


class Application(tornado.web.Application):
    def __init__(self):
        self.websockets = {}

        derby.db = derby.Database(derby.args.db)

        config = {}
        for item in derby.db.find('settings'):
            config[item['name']] = item['value']

        self.serialPort = None
        self.OpenSerialPort(config['port'])

        # class to manage the state of the track
        self.trackState = derby.TrackState()

        patterns = [
            ( r'/events/([0-9]*)', derby.handlers.Events    ),
            ( r'/racers/([0-9]*)', derby.handlers.Racers    ),
            ( r'/groups/([0-9]*)', derby.handlers.Groups    ),
            ( r'/times/([0-9]*)',  derby.handlers.Times     ),
            ( r'/config/([a-z]*)', derby.handlers.Config    ),
            ( r'/serial/test',     derby.handlers.PortTest  ),
            ( r'/serial/',         derby.handlers.Serial    ),
            ( r'/ws',              derby.handlers.WebSocket ),
            ( r'/(settings)',      derby.handlers.Template  ),
            ( r'/',                derby.handlers.Template  ),
            ]

        # Tornado settings
        self.settings = dict(
            static_path   = os.path.join(derby.root, 'static'),
            template_path = os.path.join(derby.root, 'templates'),
            debug         = derby.args.debug,
            )

        super(Application, self).__init__(patterns, **self.settings)

        try:
            self.listen(derby.args.port, derby.args.addr, xheaders=True)
        except Exception as e:
            raise

        logging.info('Listening on %s:%d', derby.args.addr, derby.args.port)

        signal.signal(signal.SIGINT,  self.SignalHandler)
        signal.signal(signal.SIGTERM, self.SignalHandler)

        ioloop.start()
        logging.info('Good-Bye')

    def Broadcast(self, action, message):
        'Broadcast a message to all connected sockets'
        bundle = {
            'action'  : action,
            'message' : message,
            }
        for websocket in self.websockets.values():
            websocket.write_message(bundle)

    def Stop(self):
        ioloop.add_callback_from_signal(ioloop.stop)

    def SignalHandler(self, signum, frame):
        if signal.SIGINT == signum:
            print()
        logging.info('Terminating')
        self.Stop()

    def OpenSerialPort(self, port):
        if self.serialPort:
            ioloop.remove_handler(self.serialPort)
            self.serialPort.close()
            self.serialPort = None

        if not port:
            return

        try:
            self.serialPort = serial.Serial(port, 9600)
        except:
            logging.info('Unable to open serial port: %s', port)
            return

        ioloop.add_handler(self.serialPort, self.SerialReadCb, ioloop.READ)
        ok = self.serialPort.write(b'hello world\n')
        print(ok)

    def SerialReadCb(self, fd, event):
        data = fd.read(fd.in_waiting)
        print(data.decode('utf-8').strip())
