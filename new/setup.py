#!/usr/bin/env python3

import sys
import os

from setuptools import setup

exec(compile(open('derby/version.py').read(),'version.py','exec'))

def findDataFiles(root):
    paths = []
    trim = len(root) + 1
    for base,directories,filenames in os.walk(root):
        if base.endswith('__pycache__'):
            continue
        for filename in filenames:
            if filename.endswith('.py'):
                continue
            paths.append(os.path.join(base, filename)[trim:])
    return paths

setup(
    name             = 'derby',
    author           = __author__,
    author_email     = __email__,
    version          = __version__,
    license          = __license__,
    description      = 'Pinewood Derby',
    long_description = open('README.rst').read(),
    url              = 'https://github.com/moertle/derby',
    entry_points = {
        'console_scripts' : [
            'derby = derby.application:main',
            ]
        },
    packages = [
        'derby',
        ],
    package_data = {
        'derby': findDataFiles('derby')
        },
    )
