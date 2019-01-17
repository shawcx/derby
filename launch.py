#!/usr/bin/env python3

import sys
import logging

import derby

if '__main__' == __name__:
    try:
        app = derby.Application()
        app.Listen()
    except derby.error as e:
        logging.error('%s', e)
        sys.exit(-1)
