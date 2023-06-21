#!/usr/bin/env python3
import json, requests, os, sys

if len(sys.argv) < 3:
    print("Usage:", sys.argv[0], "<ORG> <GLOBAL_USER>")
    exit(-2)

ORG = sys.argv[1]
GLOBAL_USER = sys.argv[2]
OUTPUT = "/home/%s/.ssh/authorized_keys" % GLOBAL_USER
TMP_OUTPUT = "/tmp/authorized_keys"

API_URL = 'https://api.github.com'
ORG_MEMBERS_URI = '/orgs/%s/members' % ORG
USER_KEYS_URI = '/users/%s/keys'
ignore_users = []

users = {}

def get_w_auth(service):
    url = '%s%s' % (API_URL, service)
    r = requests.get(url)
    return r

r = get_w_auth(ORG_MEMBERS_URI)
if r.status_code != 200:
    print("failed to access API")
    exit(-1)

try:
    os.remove(TMP_OUTPUT)
except:
    pass

with open(TMP_OUTPUT, 'w') as fi:
    for user in r.json():
        username = user['login']
        if username in ignore_users:
            continue

        service = USER_KEYS_URI % username
        ur = get_w_auth(service)

        if ur.status_code != 200:
            continue

        fi.write('# %s\n' % username)
        keys = ur.json()
        for key in keys:
            fi.write('%s\n' % key['key'])
        fi.write('\n')

if os.path.isfile(TMP_OUTPUT):
    if os.path.isfile(OUTPUT):
        os.remove(OUTPUT)
    os.rename(TMP_OUTPUT, OUTPUT)
