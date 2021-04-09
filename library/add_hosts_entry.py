#!/usr/bin/env python

from ansible.module_utils.basic import *
import sys
import re
from collections import defaultdict

MODULE_FIELDS = {
    'file': {'type': str, 'default': '/etc/hosts'},
    'hosts': {'type': set, 'required': True},
    'ips': {'type': set, 'required': True},
    'append': {'type': bool, 'required': True}
}

def read_hosts(file):
    hostsfile = defaultdict(set)
    with open(file, 'rU') as f:
        hostslines = [re.split(r'\s+', l.strip().split('#', 2)[0]) for l in f.readlines() if not l.startswith('#') and len(l.strip()) != 0]
        for h in hostslines:
            hostsfile[h[0]].update(h[1:])
    return hostsfile

def main():
    module = AnsibleModule(argument_spec=MODULE_FIELDS)

    oldhostsfile = read_hosts(module.params['file'])
    hostsfile = defaultdict(set)
    
    if module.params['append']:
        hostsfile.update(oldhostsfile)

    hosts = module.params['hosts']

    for ip in module.params['ips']:
        hostsfile[ip].update(hosts)

    changed = hostsfile != oldhostsfile
    if changed:
        with open(module.params['file'], 'w') as f:
            for ip in hostsfile:
                hostname = list(hostsfile[ip])[0]
                if hostname == '-':
                    hostname = list(hostsfile[ip])[-1]
                f.write(  f'{str(ip)}\t\t{ hostname }\n'  )

    module.exit_json(changed=changed, meta=hostsfile)

if __name__ == '__main__':
    main()
