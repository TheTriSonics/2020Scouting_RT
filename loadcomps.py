#!/usr/bin/env python3

import json
import requests
from google.cloud import firestore
from functools import lru_cache
from datetime import datetime


"""
Script to push data from The Blue Alliance into the Trisonic's Firestore.
We'll take a competition name and populate the available teams and match
numbers that they're in.
"""


@lru_cache(maxsize=2)
def _get_read_key():
    with open('tbaread.key') as f:
        key = f.read().strip()
    return key


def _tba_url():
    return 'https://www.thebluealliance.com/api/v3'


def get_headers():
    api_headers = {'X-TBA-Auth-Key': _get_read_key()}
    return api_headers


def get_events(year):
    # JJB: Ick.  Fix this.
    full_url = f"{_tba_url()}/events/2020"
    d = requests.get(full_url, headers=get_headers())
    return d.json()


def get_teams_at_event(event_key):
    full_url = f"{_tba_url()}/event/{event_key}/teams"
    d = requests.get(full_url, headers=get_headers())
    return d.json()


def get_matches_at_event(event_key):
    full_url = f"{_tba_url()}/event/{event_key}/matches"
    d = requests.get(full_url, headers=get_headers())
    return d.json()


def pretty_json(json_data):
    return json.dumps(json_data, indent=4, sort_keys=True)


def load_event(year, compname):
    year = str(year)
    compname = str(compname)
    db = firestore.Client()
    comp_col = db.collection('competitions')\
                 .document(year)\
                 .collection(compname)
    teams = get_teams_at_event(f'{year}{compname}')
    for t in teams:
        num = t['team_number']
        name = t['nickname']
        school = t['school_name']
        print(f"{num} / {name} / {school}")
        tdata = {}
        tdata['team_name'] = name
        tdata['school_name'] = school
        tdata['sort_order'] = int(num)
        comp_col.document(str(num)).set(tdata)

def show_events():
    events = get_events(2020)
    print(events)



if __name__ == '__main__':
    import sys
    year = datetime.now().year
    show_events()
    compname = sys.argv[1] or ''
    load_event(year, compname)
