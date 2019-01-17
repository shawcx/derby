
import sys
import os
import signal
import socket
import logging

import tornado.web
import tornado.ioloop

import derby

ioloop = tornado.ioloop.IOLoop.instance()


class Application(tornado.web.Application):
    def __init__(self, section='server'):
        signal.signal(signal.SIGINT,  self.SignalHandler)
        signal.signal(signal.SIGTERM, self.SignalHandler)

        self.websockets = {}

        patterns = [
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

        ioloop.start()

    def Broadcast(self, msg):
        'Broadcast a message to all connected sockets'

        for client in self.websockets:
            client.write_message(msg)

    def Stop(self):
        ioloop.add_callback(ioloop.stop)

    def SignalHandler(self, signum, frame):
        logging.info('Terminating')
        self.Stop()
