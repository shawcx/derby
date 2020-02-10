
import sys
import os
import json
import uuid
import logging

import tornado.web
import tornado.websocket

import derby


class Template(tornado.web.RequestHandler):
    def get(self, template=None):
        template = template+'.html' if template else 'index.html'
        self.render(template)


class Serial(tornado.web.RequestHandler):
    def post(self):
        racerA = self.get_argument('racerA')
        racerB = self.get_argument('racerB')

        self.settings['pipe'].send(b'MG\r')
        if racerA == '-1':
            logging.info('Masking Lane A')
            self.settings['pipe'].send(b'MA\r')
        if racerB == '-1':
            logging.info('Masking Lane B')
            self.settings['pipe'].send(b'MB\r')
        self.settings['pipe'].send(b'LN\r')
        self.set_status(204)


class Racers(tornado.web.RequestHandler):
    def get(self, racer_id=None):
        if racer_id:
            pass
        else:
            racers = derby.db.find('racers')
            times  = derby.db.find('times')
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

    def put(self, racer_id=None):
        try:
            data = json.loads(self.request.body)
        except:
            raise tornado.web.HTTPError(500)

        derby.db.update('racers', data, 'racer_id')
        self.write(data)

    def delete(self, racer_id=None):
        derby.db.delete('racers', racer_id, 'racer_id')
        derby.db.delete('times', racer_id, 'racer_id')
        self.set_status(204)


class Times(tornado.web.RequestHandler):
    def get(self, time_id=None):
        if time_id:
            pass
        else:
            times = derby.db.find('times')
            self.write(json.dumps(times))

    def post(self, time_id=None):
        results = json.loads(self.request.body)

        laneA = results.get('laneA')
        entry1 = dict(
            racer_id = laneA.get('racer'),
            lane     = 'A',
            time     = laneA.get('time'),
            )
        if entry1['racer_id'] != -1:
            try:
                derby.db.insert('times', entry1, 'time_id')
            except derby.error as e:
                self.set_status(400)
                self.write('%s', e)

        laneB = results.get('laneB')
        entry2 = dict(
            racer_id = laneB.get('racer'),
            lane     = 'B',
            time     = laneB.get('time'),
            )
        if entry2['racer_id'] != -1:
            try:
                derby.db.insert('times', entry2, 'time_id')
            except derby.error as e:
                self.set_status(400)
                self.write('%s', e)

        self.settings['pipe'].send(b'MG\r')

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
        state = self.application.trackState.state
        self.write_message(dict(action='connected', message=state))

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
