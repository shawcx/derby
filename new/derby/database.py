
import os
import sqlite3

import derby


class Database:
    def __init__(self, path):
        self.connection = None

        schema = None
        if not os.path.isfile(path):
            schemaPath = os.path.join(derby.root, 'database.sql')
            try:
                schema = open(schemaPath, 'r').read()
            except:
                raise derby.error('Could not open schema: %s', schemaPath) from None

        try:
            self.connection = sqlite3.connect(path, check_same_thread=False)
        except sqlite3.OperationalError:
            raise derby.error('Unable to open database: %s', path) from None

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
        statement = 'SELECT * FROM {0}'.format(table)
        if params:
            statement += ' WHERE ' + params
        if sort:
            statement += ' ' + sort
        cursor = self.connection.cursor()
        cursor.execute(statement)
        rows = cursor.fetchall()
        cursor.close()
        return list(dict(row) for row in rows)

    def findOne(self, table, col, value):
        statement = 'SELECT * FROM {0} WHERE {1}=?'.format(table, col)
        cursor = self.connection.cursor()
        cursor.execute(statement, (value,))
        row = cursor.fetchone()
        cursor.close()
        return dict(row) if row else None

    def insert(self, table, values, id_column='id'):
        cols = ','.join('"%s"' % s for s in values.keys())
        placeholder = ','.join('?' * len(values))
        statement = 'INSERT INTO {0} ({1}) VALUES ({2})'.format(table, cols, placeholder)

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

    def update(self, table, values, id_column='id'):
        _id = values[id_column]
        columns = ','.join('"%s"=?' % s for s in values.keys())
        statement = 'UPDATE {0} SET {1} WHERE {2}=?'.format(table, columns, id_column)
        cursor = self.connection.cursor()
        try:
            cursor.execute(statement, list(values.values()) + [_id])
        except sqlite3.ProgrammingError:
            raise derby.error('Problem executing statement')
        self.connection.commit()

    def delete(self, table, value, col='id'):
        statement = 'DELETE FROM {0} WHERE {1} = ?'.format(table, col)
        cursor = self.connection.cursor()
        cursor.execute(statement, (value,))
        self.connection.commit()
