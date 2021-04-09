#!/usr/bin/env python3
import argparse
import jinja2

from collections import namedtuple

args = {
    'node_image_id': {'type': str, 'required': True},
    'node_initial_user': {'type': str, 'default': 'ubuntu'},
    'node_flavour_master': {'type': str, 'required': True},
    'node_flavour_slave': {'type': str, 'required': True},
    'node_count_master': {'type': int, 'required': True},
    'node_count_slave': {'type': int, 'required': True},
    'ansible_user': {'type': str, 'default': 'ubuntu'},
    'ssh_key_name': {'type': str, 'required': True},
    'avail_zone': {'type': str, 'default': 'QRISCloud'},
    'project_name': {'type': str, 'required': True},
    'volume_size': {'type': int, 'default': 10},
}

parser = argparse.ArgumentParser(description='Docker Swarm Cluster HEAT Generator')

for arg in args:
    parser.add_argument('--{0}'.format(arg.replace('_', '-')), dest=arg, **args[arg])
args = parser.parse_args()

env = jinja2.Environment(loader=jinja2.FileSystemLoader('./'))

template = env.get_template('swarm.yaml.j2')

with open('swarm.yaml', 'w') as f:
    print(template.render(vars(args)), file=f)
