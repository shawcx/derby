
import sys
import os
import logging
import sqlite3
import threading

import derby


class Database:
    def __init__(self, path):
        schema = None
        if not os.path.isfile(path):
            schemaPath = os.path.join(derby.root, 'database.sql')
            schema = open(schemaPath, 'r').read()

        # make sure the database is locked since we are crossing threads
        self.sema = threading.Semaphore()

        try:
            self.connection = sqlite3.connect(path, check_same_thread=False)
        except sqlite3.OperationalError:
            raise derby.error('Unable to open database: %s', path)

        self.connection.text_factory = str
        self.connection.row_factory  = sqlite3.Row

        if schema:
            cursor = self.connection.cursor()
            cursor.executescript(schema)
            self.connection.commit()

    def __del__(self):
        self.connection.commit()
        self.connection.close()

    def find(self, table, params=None, sort=None):
        self.sema.acquire()
        statement = 'SELECT * FROM {0}'.format(table)
        if params:
            statement += ' WHERE ' + params
        if sort:
            statement += ' ' + sort
        cursor = self.connection.cursor()
        cursor.execute(statement)
        rows = cursor.fetchall()
        cursor.close()
        self.sema.release()
        return list(dict(row) for row in rows)

    def findOne(self, table, col, value):
        statement = 'SELECT * FROM {0} WHERE {1}=?'.format(table, col)
        self.sema.acquire()
        cursor = self.connection.cursor()
        cursor.execute(statement, (value,))
        row = cursor.fetchone()
        cursor.close()
        self.sema.release()
        return dict(row) if row else None

    def insert(self, table, values, id_column='id'):
        cols = ','.join(values.keys())
        placeholder = ','.join('?' * len(values))
        statement = 'INSERT INTO {0} ({1}) VALUES ({2})'.format(table, cols, placeholder)

        self.sema.acquire()
        cursor = self.connection.cursor()
        try:
            cursor.execute(statement, list(values.values()))
            if id_column not in values:
                values[id_column] = cursor.lastrowid
        except sqlite3.ProgrammingError as e:
            raise derby.error('Problem executing statement: %s', e)
        except sqlite3.IntegrityError as e:
            raise derby.error('Integrity error: %s', e)
        finally:
            cursor.close()
        self.connection.commit()
        self.sema.release()

    def update(self, table, values, id_column='id'):
        _id = values[id_column]
        columns = ','.join(s + '=?' for s in values.keys())
        statement = 'UPDATE {0} SET {1} WHERE {2}=?'.format(table, columns, id_column)
        self.sema.acquire()
        cursor = self.connection.cursor()
        try:
            cursor.execute(statement, list(values.values()) + [_id])
        except sqlite3.ProgrammingError:
            raise derby.error('Problem executing statement')
        self.connection.commit()
        self.sema.release()

    def remove(self, table, value, col='id'):
        statement = 'DELETE FROM {0} WHERE {1} = ?'.format(table, col)
        self.sema.acquire()
        cursor = self.connection.cursor()
        cursor.execute(statement, (value,))
        self.connection.commit()
        self.sema.release()
