# ansible-swarm-clowder
This repository does the following things:
* create a HEAT stack
* install neccessary tools/libraries
* deploy a swarm cluster
* deploy Clowder in that swarm cluster
All i sdone via a Makefile


Thanks to Zane for his work on Makefile and templates ...


The xapi part was added later as I did not have enough nodes previously.

1. To create a new stack: openstack stack create -t additional-xapi.yaml xxapi
2. ./make_inventory_openstack.py xxapi > xxapi_inventory.yml
3. 