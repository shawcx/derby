#!/usr/bin/env python3

import sys
import logging

import derby

if '__main__' == __name__:
    try:
        derby.Application()
    except derby.error as e:
        logging.error('%s', e)
        sys.exit(-1)
