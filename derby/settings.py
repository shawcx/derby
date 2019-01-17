
import argparse
import collections
import configparser
import json
import logging
import os
import signal
import queue
import socket
import sys

import derby


# parse the command line arguments
argparser = argparse.ArgumentParser()

#argparser.add_argument('--config',
#    metavar='<file>', default=os.path.join(derby.root, 'derby.ini'),
#    help='alternate configuration file'
#    )

argparser.add_argument('--addr',
    metavar='<ip>', default='0.0.0.0',
    help='address to listen on'
    )

argparser.add_argument('--port',
    metavar='<port>', type=int, default=8000,
    help='port to bind to'
    )

argparser.add_argument('--debug',
    action='store_true',
    help='enable debug options'
    )

derby.args = argparser.parse_args()

# Setting default stdout logging
logging.basicConfig(
    format  = '%(asctime)s %(levelname)-8s %(message)s',
    datefmt = '%Y-%m-%d %H:%M:%S',
    level   = logging.DEBUG if derby.args.debug else logging.INFO
    )
