
import logging

import derby


class TrackState:
    def __init__(self, pipe):
        self.pipe = pipe
        self._input = ''
        self.gateClosed = False
        # get the gate status
        self.pipe.send(b'RG')

    def checkQueue(self):
        data = []
        while self.pipe.poll():
            data.append(self.pipe.recv())
        if data:
            self._input += b''.join(data).decode('ascii')
            self.parse()

    def parse(self):
        while self._input:
            logging.debug('### %d %s', len(self._input), repr(self._input))
            if self._input.startswith('@'):
                self.gateClosed = True
                self._input = self._input[1:]
                continue
            if self._input.startswith('>'):
                self.gateClosed = True
                self._input = self._input[1:]
                continue
            if self._input.startswith('RG0'):
                self.gateClosed = False
                self._input = self._input[3:]
                continue
            if self._input.startswith('RG1'):
                self.gateClosed = True
                self._input = self._input[3:]
                continue
            if self._input.startswith('\r'):
                self._input = self._input[1:]
                continue
            if self._input.startswith('\n'):
                self._input = self._input[1:]
                continue
            if self._input.startswith('A='):
                # did not receive all the results yet
                if len(self._input) < 60:
                    print('not complete')
                    break
                self.parseResults(self._input[:60])
                self._input = self._input[60:]

            # test if \r\n has been sent
            try:
                crnl = self._input.index('\r')
            except ValueError:
                break

            unknown = self._input[:crnl]
            self._input = self._input[crnl+1:]
            logging.debug('IGNORED: %s', repr(unknown))

    def parseResults(self, rawResults):
# Example return data
# 'A=0.9682! B=1.5024" C=0.0000  D=0.0000  E=0.0000  F=0.0000  '
        try:
            timeA = float(rawResults[ 2: 8])
            timeB = float(rawResults[12:18])
        except ValueError:
            print('something went terrible wrong!')
            print(repr(rawResults))
            print()
        print('RESULTS:', timeA, timeB)
