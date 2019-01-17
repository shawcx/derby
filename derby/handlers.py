
import sys
import os
import json
import uuid

import tornado.web
import tornado.websocket

class Template(tornado.web.RequestHandler):
    def get(self, template=None):
        template = template+'.html' if template else 'index.html'
        self.render(template)


class WebSocket(tornado.websocket.WebSocketHandler):
    def __init__(self, application, request, **kwargs):
        super(WebSocket, self).__init__(application, request, **kwargs)
        self.wsid = str(uuid.uuid4())

    def check_origin(self, origin):
        return True

    def open(self):
        self.set_nodelay(True)
        self.application.websockets[self.wsid] = self
        self.write_message(dict(action='connected', wsid=self.wsid))

    def on_message(self, msg):
        if msg == 'ping':
            return

        for ws in self.application.websockets.items():
            if ws is self:
                continue
            ws.write_message(msg)

    def on_close(self):
        try:
            del self.application.websockets[self.wsid]
        except KeyError:
            pass
