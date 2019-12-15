#!/usr/bin/env python3

import logging
import multiprocessing
import sys

import derby

if '__main__' == __name__:
    multiprocessing.freeze_support()

    # pipes for the serial reader process
    localPipe,remotePipe = multiprocessing.Pipe()

    # start the serial reader process
    try:
        serialWorker = derby.SerialWorker(remotePipe)
        serialWorker.start()
    except derby.error as e:
        serialWorker = None
        logging.error('%s', e)
        sys.exit(-1)

    try:
        derby.Application(localPipe)
    except derby.error as e:
        logging.error('%s', e)
        sys.exit(-1)

    serialWorker.join()
