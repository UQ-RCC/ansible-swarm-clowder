#!/usr/bin/env python3
import sys
import os
import novaclient.client
import cinderclient.client
import keystoneclient.client
import keystoneauth1.identity.v3
import keystoneauth1.session
import heatclient.client
import yaml
from collections import defaultdict

if len(sys.argv) != 2:
	sys.stderr.write('Usage: {0} <stack_name>\n'.format(sys.argv[0]))
	exit(2)

stack_name = sys.argv[1]

auth = keystoneauth1.identity.v3.Password(
	auth_url=os.environ['OS_AUTH_URL'],
	username=os.environ['OS_USERNAME'],
	password=os.environ['OS_PASSWORD'],
	project_name=os.environ['OS_PROJECT_NAME'],
	user_domain_name=os.environ['OS_USER_DOMAIN_NAME'],
	#project_domain_name=os.environ['OS_PROJECT_DOMAIN_NAME']
	project_domain_id=os.environ['OS_PROJECT_DOMAIN_ID']
)

sess = keystoneauth1.session.Session(auth=auth)
keystone = keystoneclient.client.Client(session=sess)

heat = heatclient.client.Client(version=1, session=sess)
nova = novaclient.client.Client(version=2, session=sess)
cinder = cinderclient.client.Client(version=2, session=sess)

stacks = [s for s in heat.stacks.list(filters={'stack_name': stack_name})]
if len(stacks) == 0:
	print('No such stack', file=sys.stderr)
	exit(1)

stack = stacks[0]

def get_all_servers(heat, stack_id, servers):
	#print('get_all_servers({0})'.format(stack_id))
	resources = [r for r in heat.resources.list(stack_id)]
	for res in resources:
		#print('type = {0}'.format(res.resource_type))
		if res.resource_type == 'OS::Nova::Server':
			servers.append(res.physical_resource_id)
		elif res.resource_type in [
			'OS::Neutron::FloatingIP',
			'OS::Neutron::Port',
			'OS::Neutron::Net',
			'OS::Neutron::Router',
			'OS::Heat::CloudConfig',
			'OS::Heat::MultipartMime',
			'OS::Cinder::Volume',
			'OS::Cinder::VolumeAttachment',
			'OS::Neutron::RouterInterface',
			'OS::Neutron::Subnet'
			]:
			continue
		else:
			#print(res.resource_type)
			#print(res.physical_resource_id)
			get_all_servers(heat, res.physical_resource_id, servers)

servers_ids = []
get_all_servers(heat, stack.id, servers_ids)

groups = defaultdict(set)
hostvars = defaultdict(dict)

servers = [s for s in nova.servers.list(search_opts={'id': servers_ids})]

for s in servers:
	if 'ansible_host_groups' not in s.metadata:
		continue

	for group in s.metadata['ansible_host_groups'].split(','):
		groups[group].add(s.name)

	hvars = hostvars[s.name]
	hvars['ansible_ssh_user'] = s.metadata['ansible_ssh_user']
	hvars['initial_ssh_user'] = s.metadata['initial_ssh_user']
	hvars['ansible_ssh_host'] = s.networks['qld'][0] ### need to change this ot make it more generic
	hvars['secondary-ip'] = s.networks['qld-data'][0] ### need to change this ot make it more generic
	
	volumes = [v for v in nova.volumes.get_server_volumes(s.id) if v.device != '/dev/vda']
	if len(volumes) == 0:
		continue

	hvars['ansible_host_volumes'] = {cinder.volumes.get(vol.volumeId).name:{'dev': vol.device, 'uuid': vol.volumeId} for vol in volumes}


inventory = {g:{'hosts':{h:None for h in groups[g]}} for g in groups}
inventory['all'] = {
	'hosts': dict(hostvars),
	'vars': {o['output_key']:stack.output_show(o['output_key'])['output']['output_value'] for o in stack.output_list()['outputs']}
}


# So we get "host:" instead of "host: {}"
yaml.SafeDumper.add_representer(
	type(None),
	lambda dumper, value: dumper.represent_scalar(u'tag:yaml.org,2002:null', '')
)
print(yaml.safe_dump(inventory, default_flow_style=False))
