import requests
import MySQLdb


def hello_world():
    assert MySQLdb
    return requests.get('https://armooo.net/keybase.txt').text.encode('utf-8')
