import requests


def hello_world():
    return requests.get('https://armooo.net/keybase.txt').text.encode('utf-8')
