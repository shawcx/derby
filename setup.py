#!/usr/bin/env python3

import sys
import os

import setuptools

exec(compile(open('derby/version.py').read(),'version.py','exec'))

setuptools.setup(
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
    packages = setuptools.find_packages(),
    include_package_data = True,
    install_requires = [
        'tornado',
        'pyserial',
        ],
    zip_safe = False
    )
