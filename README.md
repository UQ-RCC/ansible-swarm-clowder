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

## Destroy Clowder in swarm

* **make destroy-clowder**

## Destroy swarm cluster

* **make destroy-swarm**

## Restart glusterd and autofs

* **make reloadautofs**

## Check/restart gluster volumes

On worker/slave nodes

* **sudo gluster volume status all**
* **sudo gluster volume stop gfs**
* **sudo gluster volume start gfs**

gfs volume status should show 3 bricks and 3 daemons online

## Check clowder overlay network

* Network should be okay if each traefik/xapi container has an IP address and 6 peers

  * **make inspect-network**

## Docker system prune

* Prune orphaned docker images, containers, networks, build cache, and restart
  docker daemon. Cleans up orphaned resources in docker system on each node.

  * **make prune-docker**

## Redeploy xxapi1 and xxapi2

1. remove xapi stack on xxapi1 and xxapi2

   * **make xxapi-destroy**

   optional

   * **docker service ls**
   * **docker stack rm xapi**
   * **docker ps**
   * **docker system prune -f**
   * **docker network create clowder --driver overlay --scope swarm**

2. deploy from github/ansible-swarm-clowder

   * **make xxapi-deploy**

## Delete stack

* **make destroy-stack**

# Deployment approaches

## Set target environment

To change the target environment for deployment steps (requires soft-links to
inventory.yml and secrets.yml)

* For production deployments use

  * **make setenv-prod**

* For development deployments use

  * **make setenv-dev**

## App redeploy only

1. Remove app

   * **make destroy-clowder**

2. Deploy app

   * **make deploy-clowder**

## App and swarm redeploy

1. Remove app

   * **make destroy-clowder**

2. Remove swarm cluster

   * **make destroy-swarm**

3. Build swarm cluster

   * **make init-swarm**

4. Deploy app

   * **make deploy-clowder**

## Full redeploy with docker prune

1. Remove app

   * **make destroy-clowder**

2. Remove swarm cluster

   * **make destroy-swarm**

3. Prune docker

   * **make prune-docker**

4. Restart gluster and autofs

   * **make reloadautofs**

5. Build swarm cluster

   * **make init-swarm**

6. Deploy app

   * **make deploy-clowder**

# Node apt-updates and reboots

Remove app, swarm cluster, then stop gfs volume

   * **make gfs-stop**
   * **make gfs-status**
   * **make apt-update**
   * **make reboot**
   * **mark uptime**
   * **make gfs-start**
   * **make gfs-status**

Then build swarm and deploy app

For xxapi apt-update and reboot

   * **make xxapi-apt-update**
   * **make xxapi-reboot**
