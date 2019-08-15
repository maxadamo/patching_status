#!/usr/bin/env python3
"""
  parses puppetDB Json removing unnecessary keys

  Curl example to fetch data from PuppetDB:
  curl -s -X POST http://puppetdb.domain.org:8080/pdb/query/v4/facts \
    -H 'Content-Type:application/json' \
    -d '{"query": ["and",["=", "name", "os_patching"]], "pretty": "true", "limit": 4}'
"""
from ast import literal_eval
import json
import datetime
import configparser
import requests


def write_file(file_name, file_content, file_path, dump=True):
    """ insert data to file """
    if dump:
        file_dump = json.dumps(file_content, indent=2, sort_keys=True)
    else:
        file_dump = file_content
    with open('{}/{}'.format(file_path, file_name), 'w') as my_file:
        my_file.write(file_dump)
    my_file.close()


if __name__ == "__main__":
    TIMENOW = str(datetime.datetime.now()).split('.')[0]
    CONFIG = configparser.RawConfigParser()
    CONFIG.read('<%= $python_base %>/.patching_status.conf')

    PUPPETDB = CONFIG.get('patching', 'puppetdb')
    PUPPETDB_PORT = CONFIG.get('patching', 'puppetdb_port')
    WEB_BASE = CONFIG.get('patching', 'web_base')
    SUBKEYS_LIST = CONFIG.get('patching', 'subkeys_list')
    PARAMS = '{"query": ["and",["=", "name", "os_patching"]]}'
    PARAMS_OS = '{"query": ["and",["=", "name", "lsbdistdescription"]]}'

    REQ = requests.post("http://{}:{}/pdb/query/v4/facts".format(
        PUPPETDB, PUPPETDB_PORT), PARAMS)
    REQ_OS = requests.post("http://{}:{}/pdb/query/v4/facts".format(
        PUPPETDB, PUPPETDB_PORT), PARAMS_OS)
    JSON_DATA = json.loads(REQ.text)
    JSON_DATA_OS = literal_eval(REQ_OS.text)
    NEW_LIST = []

    for item in enumerate(JSON_DATA):
        list_item = item[0]
        NEW_LIST.append({})

        for key, value in JSON_DATA[list_item].items():
            if key == 'certname':
                hostname = JSON_DATA[list_item][key]
                NEW_LIST[list_item][key] = hostname
                os_release = next(JSON_DATA_OS for JSON_DATA_OS in JSON_DATA_OS if JSON_DATA_OS["certname"] == hostname)['value'] #pylint: disable=C0301
                NEW_LIST[list_item]['lsbdistdescription'] = os_release
            elif key == 'value':
                for subkey, subvalue in JSON_DATA[list_item]['value'].items():
                    if subkey in SUBKEYS_LIST:
                        NEW_LIST[list_item][subkey] = JSON_DATA[list_item]['value'][subkey]
            if JSON_DATA[list_item]['value']['reboots']['reboot_required']:
                NEW_LIST[list_item]['reboot_required'] = 'Y'
            else:
                NEW_LIST[list_item]['reboot_required'] = 'N'

    # sorting list of dictionaries by value: https://stackoverflow.com/a/73050/3151187
    SORTED_UPDT = sorted(NEW_LIST, key=lambda k: k['package_update_count'], reverse=True)
    SORTED_SECUPD = sorted(NEW_LIST, key=lambda k: k['security_package_update_count'], reverse=True)
    SORTED_REBOOT = sorted(NEW_LIST, key=lambda k: k['reboot_required'], reverse=True)
    SORTED_CERTNAME = sorted(NEW_LIST, key=lambda k: k['certname'])
    SORTED_LSBDESC = sorted(NEW_LIST, key=lambda k: k['lsbdistdescription'])
    TIMESTAMP_JS = """var mytimestamp = "This report was generated at {} GMT"
document.getElementById("factstimestamp").innerHTML = mytimestamp;\n""".format(TIMENOW)

    write_file('puppetdb_updates.json', SORTED_UPDT, WEB_BASE)
    write_file('puppetdb_sec_updates.json', SORTED_SECUPD, WEB_BASE)
    write_file('puppetdb_reboot.json', SORTED_REBOOT, WEB_BASE)
    write_file('puppetdb_certname.json', SORTED_CERTNAME, WEB_BASE)
    write_file('puppetdb_lsbdistdescription.json', SORTED_LSBDESC, WEB_BASE)
    write_file('timestamp.js', TIMESTAMP_JS, WEB_BASE, dump=None)
