
import sys
import os
import json
import uuid
import logging

import serial
import serial.tools.list_ports
import tornado.web
import tornado.websocket

import derby


class Template(tornado.web.RequestHandler):
    def get(self, path=None):
        template = path+'.html' if path else 'index.html'
        self.render(template, active=path)


class Events(tornado.web.RequestHandler):
    def get(self, event_id=None):
        if not event_id:
            events = derby.db.find('events')
            self.set_header('Content-Type', 'application/json')
            self.write(json.dumps(events))
        else:
            event = derby.db.findOne('events', 'event_id', event_id)
            if event is None:
                self.redirect('/')
            else:
                self.render('event.html', event=event)

    def post(self, event_id=None):
        try:
            data = json.loads(self.request.body)
        except:
            raise tornado.web.HTTPError(500)

        try:
            derby.db.insert('events', data, 'event_id')
            self.write(data)
        except derby.error:
            self.set_status(400)
            self.write('Duplicate name')

    def put(self, event_id=None):
        try:
            data = json.loads(self.request.body)
        except:
            raise tornado.web.HTTPError(500)

        derby.db.update('events', data, 'event_id')
        self.write(data)

    def delete(self, event_id=None):
        derby.db.delete('events', event_id, 'event_id')
        self.set_status(204)


class Groups(tornado.web.RequestHandler):
    def get(self, event_id=None):
        if event_id:
            groups = derby.db.find('groups', 'event_id='+event_id)
            self.write(json.dumps(groups))
        else:
            raise tornado.web.HTTPError(500)

    def post(self, group_id=None):
        try:
            data = json.loads(self.request.body)
        except:
            raise tornado.web.HTTPError(500)

        try:
            derby.db.insert('groups', data, 'group_id')
            self.write(data)
            self.application.Broadcast('groups', data)
        except derby.error as e:
            self.set_status(400)
            self.write(str(e))

    def put(self, racer_id=None):
        try:
            data = json.loads(self.request.body)
        except:
            raise tornado.web.HTTPError(500)

        derby.db.update('groups', data, 'group_id')
        self.write(data)
        self.application.Broadcast('groups', data)

    def delete(self, group_id=None):
        derby.db.delete('groups', group_id, 'group_id')
        self.application.Broadcast('groupRemove', group_id)
        self.set_status(204)


class Racers(tornado.web.RequestHandler):
    def get(self, event_id=None):
        if event_id:
            racers = derby.db.find('racers', 'event_id='+event_id)
            self.write(json.dumps(racers))
        else:
            raise tornado.web.HTTPError(500)

    def post(self, racer_id=None):
        try:
            data = json.loads(self.request.body)
        except:
            raise tornado.web.HTTPError(500)

        try:
            derby.db.insert('racers', data, 'racer_id')
            self.write(data)
            self.application.Broadcast('racers', data)
        except derby.error:
            self.set_status(400)
            self.write('Duplicate name')

    def put(self, racer_id=None):
        try:
            data = json.loads(self.request.body)
        except:
            raise tornado.web.HTTPError(500)

        try:
            derby.db.update('racers', data, 'racer_id')
            self.write(data)
            self.application.Broadcast('racers', data)
        except derby.error:
            self.set_status(400)
            self.write('Duplicate name')

    def delete(self, racer_id=None):
        derby.db.delete('racers', racer_id, 'racer_id')
        derby.db.delete('times',  racer_id, 'racer_id')
        self.application.Broadcast('racerRemove', racer_id)
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
            event_id = results.get('event_id'),
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
            event_id = results.get('event_id'),
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

        self.application.SerialWrite('MG')

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
        self.write_message(dict(action='trackState', message=self.application.state))

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


class Config(tornado.web.RequestHandler):
    def get(self, name=None):
        self.set_header('Content-Type', 'application/json')
        if not name:
            settings = derby.db.find('settings')
            self.write(json.dumps(settings))
        else:
            value = derby.db.findOne('settings', 'name', name)
            self.write({name,value})

    def put(self, name):
        data = json.loads(self.request.body)
        derby.db.update('settings', data, 'name')
        if data['name'] == 'port':
            self.application.OpenSerialPort(data['value'])
        self.set_status(204)



class Serial(tornado.web.RequestHandler):
    def get(self):
        self.set_header('Content-Type', 'application/json')
        ports = [{'port':port.device} for port in serial.tools.list_ports.comports()]
        if derby.args.debug:
            ports.append({'port':'/dev/ttyDERBY'})
        self.write(json.dumps(ports))

    def post(self):
        racerA = self.get_argument('racerA')
        racerB = self.get_argument('racerB')

        ok = self.application.SerialWrite('MG')
        if racerA == '-1':
            logging.info('Masking Lane A')
            self.application.SerialWrite('MA')
        if racerB == '-1':
            logging.info('Masking Lane B')
            self.application.SerialWrite('MB')
        ok = self.application.SerialWrite('LN')
        self.set_status(204)


class PortTest(tornado.web.RequestHandler):
    def post(self):
        testPort = self.request.body.decode('utf-8')
        current = self.application.state.get('portOpen')

        if testPort == current:
            serialPort = self.application.serialPort
        else:
            try:
                serial.Serial(testPort)
            except Exception as e:
                logging.error('%s', e)
                raise tornado.web.HTTPError(500)

        serialPort.write('RS')

        self.set_status(204)
