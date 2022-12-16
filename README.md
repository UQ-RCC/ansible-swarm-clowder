This repository performs a complete deployment of Clowder in Docker Swarm on Openstack using Ansible. 
Once deployed, the following services are going to be created: 

* a mongodb cluster spanning across the slave nodes
* an elasticearch cluster spanning across the slave nodes
* clowder instances spanning across the slave nodes
* traefik instances spanning across master nodes
* a glusterfs shared amongst slave nodes for uploads, thumbnails and previews

Makefile is used to control all the steps. 
This is the simplified version of github.com/UQ-RCC/ansible-swarm-clowder. 

Thanks to Zane Van Iperen for his work on Makefile and templates. 

# Deployment steps

## Requirements

* You need to have openstack 5.2.0 installed (apt install python3-openstackclient)
* Download the Openstack RC file
* Ansible version 2.9 
* Make installed, in ubuntu: sudo apt-get install build-essential
* Python 3
* Create vars/secrets.yml based on vars/secrets.yml.example

## Create HEAT stack for Docker Swarm

* edit setupenv-openstack. Make sure you get the IMAGE_ID and OS_PROJECT_NAME right.The IMAGE_ID should be a Ubuntu image.  

* **make stack**
* Create a FQDN that points to the first master node, this FQDN should match clowder_host field in vars/secrets.yml

## Deploy Docker swarm

* edit Clowder's custom.conf and custom.play.plugin at roles/clowder-swarm-setup/templates. 
* **make init-swarm**
* To inspect swarm cluster: **make inspect-swarm**


## Deploy Clowder in swarm

* **make deploy-clowder**

### 

## Destroy Clowder in swarm

* **make destroy-clowder**

## Destroy swarm cluster

* **make destroy-swarm**

## Restart glusterd and autofs

* **make reloadautofs**

## Check/restart gluster volumes

* **gluster volume status all**
* **gluster volume stop gfs**
* **gluster volume start gfs**

## Delete stack

* **make destroy-stack**

## Redeploy xxapi1 and xxapi2

* remove xapi stack on xxapi1 and xxapi2
  * **docker service ls**
  * **docker stack rm xapi**
  * **docker service ls**
  * **docker ps**
* deploy from github/ansible-swarm-clowder
  * **ansible-playbook -i ../pitschi-secrets/xxapi_inventory.yml xxapi.yml**
