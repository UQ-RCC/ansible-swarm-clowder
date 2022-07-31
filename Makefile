HEAT_TEMPLATE=swarm.yaml

check-vars:
	test -n "$(SSH_KEY_NAME)" # $$SSH_KEY_NAME
	test -n "$(STACK_NAME)" # $$STACK_NAME
	test -n "$(OS_PROJECT_NAME)" # $$OS_PROJECT_NAME

stack: check-vars validate
	openstack stack create \
		-t ${HEAT_TEMPLATE} ${STACK_NAME}

update: check-vars validate
	openstack stack update -t ${HEAT_TEMPLATE} ${STACK_NAME}

${HEAT_TEMPLATE}: ${HEAT_TEMPLATE}.j2 gen-swarm-template.py
	./gen-swarm-template.py \
		--node-image-id=356ff1ed-5960-4ac2-96a1-0c0198e6a999 \
		--node-initial-user=ubuntu \
		--node-flavour-master=m3.small \
		--node-flavour-slave=m3.medium \
		--node-count-master=3 \
		--node-count-slave=3 \
		--ansible-user=ubuntu \
		--ssh-key-name=${SSH_KEY_NAME} \
		--avail-zone=QRIScloud \
		--project-name=${STACK_NAME}

destroy-stack:
	openstack stack delete -y ${STACK_NAME}

validate: ${HEAT_TEMPLATE}
	openstack orchestration template validate -t ${HEAT_TEMPLATE} # > /dev/null

clean:
	rm -f inventory.yml swarm.yaml

inventory.yml: ${HEAT_TEMPLATE} make_inventory_openstack.py
	./make_inventory_openstack.py ${STACK_NAME} > $@

inventories: check-vars inventory.yml

# bootstrap: inventories bootstrap.yml
bootstrap: bootstrap.yml
	ansible-playbook -i inventory.yml bootstrap.yml

reloadautofs: autofs-reload.yml
	ansible-playbook -i inventory.yml autofs-reload.yml

init-swarm: init-swarm-cluster.yml
	ansible-playbook -i inventory.yml init-swarm-cluster.yml

inspect-swarm: inspect-swarm-cluster.yml
	ansible-playbook -i inventory.yml inspect-swarm-cluster.yml

destroy-swarm: destroy-swarm-cluster.yml
	ansible-playbook -i inventory.yml destroy-swarm-cluster.yml

deploy-clowder: clowder.yml
	ansible-playbook -i inventory.yml clowder.yml --tags=setup

destroy-clowder: clowder.yml
	ansible-playbook -i inventory.yml clowder.yml --tags=destroy

# backup-clowder: clowder.yml
# 	ansible-playbook -i inventory.yml clowder.yml --tags=backup

# monitor: clowder.yml
# 	ansible-playbook -i inventory.yml clowder.yml --tags=monitor

upgrade: upgrade.yml
	ansible-playbook -i inventory.yml upgrade.yml
.PHONY: check-vars clean stack inventories bootstrap inventory.yml init-swarm
