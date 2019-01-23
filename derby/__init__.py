
import os

root = os.path.dirname(__file__)
root = os.path.join(root, '..')
root = os.path.abspath(root)

# a generic error class for throwing exceptions
class error(Exception):
    def __init__(self, fmt, *args):
        self.message = fmt % args

    def __str__(self):
        return self.message

from . import settings
from . import database
from . import handlers
from .serialworker import SerialWorker
from .application  import Application
