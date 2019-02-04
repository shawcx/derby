
import sys
import os
import multiprocessing
import signal
import socket
import logging

import tornado.web
import tornado.ioloop

import derby

ioloop = tornado.ioloop.IOLoop.instance()


class Application(tornado.web.Application):
    def __init__(self, section='server'):
        self.websockets   = {}
        self.input_queue  = multiprocessing.Queue()
        self.output_queue = multiprocessing.Queue()

        self.serialWorker = derby.SerialWorker(self.input_queue, self.output_queue)
        self.serialWorker.daemon = True
        self.serialWorker.start()

        self.scheduler = tornado.ioloop.PeriodicCallback(self.checkQueue, 100)
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

    def Listen(self):
        try:
            self.listen(derby.args.port, derby.args.addr, xheaders=True)
        except socket.gaierror as e:
            raise derby.error('Could not listen: %s' % e)
        except socket.error as e:
            raise derby.error('Could not listen: %s' % e)
        except Exception as e:
            logging.exception('Exception on listen')
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
        self.serialWorker.shouldStop = True
        self.serialWorker.join()

    def SignalHandler(self, signum, frame):
        print()
        logging.info('Terminating')
        self.Stop()

    def checkQueue(self):
        if not self.output_queue.empty():
            message = {
                'action'  : 'serial',
                'message' : self.output_queue.get(),
                }
            print('>>>', message)
            for client in self.websockets.values():
                client.write_message(message)
