
import logging

import derby


class TrackState:
    def __init__(self, pipe):
        self.pipe = pipe
        self._input = ''
        self.state = {
            'gateClosed' : False,
        }
        # ensure the new time format is used
        self.pipe.send(b'N2')
        # get the gate status
        self.pipe.send(b'RG')

    def set(self, name, value):
        self.state[name] = value
        derby.app.Broadcast('trackState', self.state)

    def readSerialPort(self):
        # collect buffered data from serial port
        data = []
        while self.pipe.poll():
            data.append(self.pipe.recv())
        if not data:
            return

        # append data to the input queue to be processed
        self._input += b''.join(data).decode('ascii')

        # iterate over the input data to parse values
        while self._input:
            if self._input.startswith('>'):
                logging.debug('Gate Open')
                self.set('gateClosed', False)
                self._input = self._input[1:]
                continue
            if self._input.startswith('@'):
                logging.debug('Gate Closed')
                self.set('gateClosed', True)
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
            if self._input.startswith('\r'): # carriage return
                self._input = self._input[1:]
                continue
            if self._input.startswith('\n'): # new line
                self._input = self._input[1:]
                continue
            if self._input.startswith('A='):
                # did not receive all the results yet
                if len(self._input) < 60:
                    print('not complete')
                    break
                logging.debug('Results: %s', self._input[:60])
                self.parseResults(self._input[:60])
                self._input = self._input[60:]

            logging.debug('### %d %s', len(self._input), repr(self._input))

            # test if \r\n has been sent
            try:
                cr = self._input.index('\r')
            except ValueError:
                # not enough data to continue parsing
                break

            unknown = self._input[:cr]
            self._input = self._input[cr+1:]
            logging.debug('IGNORED: %s', repr(unknown))

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
            derby.app.Broadcast('exception', 'invalid race results')
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
        derby.app.Broadcast('raceResults', results)
