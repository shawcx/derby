
import sys
import os
import json
import uuid

import tornado.web
import tornado.websocket

import derby


class Template(tornado.web.RequestHandler):
    def get(self, template=None):
        template = template+'.html' if template else 'index.html'
        self.render(template)


class Serial(tornado.web.RequestHandler):
    def get(self):
        self.write('yep')
        self.settings['pipe'].send(b'LN')


class Racers(tornado.web.RequestHandler):
    def get(self, racer_id=None):
        if racer_id:
            pass
        else:
            racers = derby.db.find('racers')
            self.write(json.dumps(racers))

    def post(self, racer_id=None):
        try:
            data = json.loads(self.request.body)
        except:
            raise tornado.web.HTTPError(500)

        try:
            derby.db.insert('racers', data, 'racer_id')
            self.write(data)
        except derby.error:
            self.set_status(400)
            self.write('Duplicate name')

    def delete(self, racer_id=None):
        derby.db.delete('racers', racer_id, 'racer_id')
        self.set_status(204)


class WebSocket(tornado.websocket.WebSocketHandler):
    def __init__(self, application, request, **kwargs):
        super(WebSocket, self).__init__(application, request, **kwargs)
        self.wsid = str(uuid.uuid4())

    def check_origin(self, origin):
        return True

    def open(self):
        self.set_nodelay(True)
        self.application.websockets[self.wsid] = self
        self.write_message(dict(action='connected', message=self.wsid))

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
