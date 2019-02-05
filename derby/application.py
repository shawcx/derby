
import sys
import os
import argparse
import collections
import configparser
import json
import logging
import multiprocessing
import queue
import signal
import socket

import tornado.web
import tornado.ioloop

import derby

ioloop = tornado.ioloop.IOLoop.instance()

# parse the command line arguments
argparser = argparse.ArgumentParser()

argparser.add_argument('--serial',
    metavar='<tty>', default='/dev/ttyUSB0',
    help='serial port to open'
    )

argparser.add_argument('--baud',
    metavar='<speed>', type=int, default=9600,
    help='serial port speed'
    )

argparser.add_argument('--db',
    metavar='<sqlite db>', type=str, default='derby.sqlite',
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
    def __init__(self, section='server'):
        derby.app = self

        self.websockets = {}

        ricochet.db = derby.Database(derby.args.db)

        # pipes for the serial reader process
        self.trackPipe,remotePipe = multiprocessing.Pipe()
        # start the serial reader process
        self.serialWorker = derby.SerialWorker(remotePipe)
        self.serialWorker.start()

        # class to manage the state of the track
        self.trackState = derby.TrackState(self.trackPipe)

        # periodically check the serial pipe for data
        self.scheduler = tornado.ioloop.PeriodicCallback(self.trackState.checkQueue, 50)
        self.scheduler.start()

        patterns = [
            ( r'/serial',   derby.handlers.Serial    ),
            ( r'/(config)', derby.handlers.Template  ),
            ( r'/ws',       derby.handlers.WebSocket ),
            ( r'/',         derby.handlers.Template  ),
            ]

        # Tornado settings
        self.settings = dict(
            static_path   = os.path.join(derby.root, 'static'),
            template_path = os.path.join(derby.root, 'templates'),
            debug         = derby.args.debug
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

    def Broadcast(self, msg):
        'Broadcast a message to all connected sockets'
        for client in self.websockets:
            client.write_message(msg)

    def Stop(self):
        self.scheduler.stop()
        ioloop.add_callback(ioloop.stop)
        self.trackPipe.send(None)
        self.serialWorker.join()

    def SignalHandler(self, signum, frame):
        print()
        logging.info('Terminating')
        self.Stop()

    #if not self.fromTrackQueue.empty():
    #    message = {
    #        'action'  : 'serial',
    #        'message' : self.fromTrackQueue.get(),
    #        }
    #    #print('>>>', message)
    #    for client in self.websockets.values():
    #        client.write_message(message)
