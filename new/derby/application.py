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
        self.state = {
            'portOpen'   : None,
            'gateClosed' : None,
        }

        derby.db = derby.Database(derby.args.db)

        config = {}
        for item in derby.db.find('settings'):
            config[item['name']] = item['value']

        self.serialPort = None
        self.OpenSerialPort(config['port'])

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
            self.set('portOpen', port)
        except:
            logging.info('Unable to open serial port: %s', port)
            self.set('portOpen', None)
            return

        self._input = ''
        ioloop.add_handler(self.serialPort, self.SerialReadCb, ioloop.READ)

        # unmask lanes
        self.serialPort.write(b'MG')
        # ensure the new time format is used
        self.serialPort.write(b'N2')
        # get the gate status
        self.serialPort.write(b'RG')

    def SerialReadCb(self, fd, event):
        data = self.serialPort.read(self.serialPort.in_waiting)
        try:
            data = data.decode('ascii')
        except UnicodeDecodeError:
            logging.warn('Discarding data: %s', repr(data[0]))
        self._input += data

        while self._input:
            logging.debug('BUFFER: %s', repr(self._input))

            if self._input[0] == '>':
                logging.debug('Gate Open')
                self.set('gateClosed', False)
                self._input = self._input[1:]
                continue

            if self._input[0] == '@':
                logging.debug('Gate Closed')
                self.set('gateClosed', True)
                self._input = self._input[1:]
                continue

            if self._input[0] == '*':
                self._input = self._input[1:]
                continue

            if self._input.startswith('RG0'):
                logging.debug('Query Gate Open')
                self.set('gateClosed', False)
                self._input = self._input[3:]
                continue

            if self._input.startswith('RG1'):
                logging.debug('Query Gate Closed')
                self.set('gateClosed', True)
                self._input = self._input[3:]
                continue

            if self._input.startswith('N2'):
                logging.debug('Timing Mode Set')
                self.set('timingSet', True)
                self._input = self._input[2:]
                continue

            if self._input[0] == '\r': # carriage return
                self._input = self._input[1:]
                continue

            if self._input[0] == '\n': # new line
                self._input = self._input[1:]
                continue

            if self._input.startswith('MG'): # enable all lanes
                self._input = self._input[2:]
                continue

            if self._input.startswith('AC'): # response to MG
                self._input = self._input[2:]
                continue

            if self._input.startswith('MA'): # mask lane A
                self._input = self._input[2:]
                continue

            if self._input.startswith('MB'): # make lane B
                self._input = self._input[2:]
                continue

            if self._input.startswith('LN'): # release gate
                self._input = self._input[2:]
                continue

            if self._input.startswith('A='):
                # did not receive all the results yet
                if len(self._input) < 60:
                    break
                logging.debug('Results: %s', self._input[:60])
                self.parseResults(self._input[:60])
                self._input = self._input[60:]
                continue

            # test if \r\n has been sent
            try:
                cr = self._input.index('\r')
            except ValueError:
                # not enough data to continue parsing
                break

            unknown = self._input[:cr]
            self._input = self._input[cr+1:]
            logging.debug('IGNORED: %s', repr(unknown))


    def set(self, name, value):
        self.state[name] = value
        self.Broadcast('trackState', self.state)

    def parseResults(self, rawResults):
        # Example return data, 60 bytes
        # 'A=0.9682! B=1.5024" C=0.0000  D=0.0000  E=0.0000  F=0.0000  '
        try:
            timeA = float(rawResults[ 2: 8])
            timeB = float(rawResults[12:18])
            # unused on pack 30's 2-lane track
            #timeC = float(rawResults[22:28])
            #timeD = float(rawResults[32:38])
            #timeE = float(rawResults[42:48])
            #timeF = float(rawResults[52:58])
        except ValueError:
            self.Broadcast('exception', 'invalid race results')
            logging.error('Parse error: %s', repr(rawResults))
            return

        results = {
            'A' : timeA,
            'B' : timeB,
            #'C' : timeC, # unused
            #'D' : timeD, # unused
            #'E' : timeE, # unused
            #'F' : timeF, # unused
        }
        logging.info('A: %s B: %s', timeA, timeB)
        self.Broadcast('raceResults', results)
