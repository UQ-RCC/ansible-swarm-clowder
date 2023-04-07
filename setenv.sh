#!/bin/bash

run_dir=ansible-swarm-clowder
secrets_dir=../pitschi-secrets

if [ "${PWD##*/}" != "$run_dir" ] ; then
  echo "script must be run in $run_dir"
  exit 1
fi
if [ ! -d "$secrets_dir" ] ; then
  echo "secrets dir not found: $secrets_dir"
  exit 2
fi

if [ "$1" == "dev" ] ; then
  inventory_yml=inventory-dev.yml
  secrets_yml=secrets_dev.yml
else
  inventory_yml=inventory-stage6.yml
  secrets_yml=secrets_prod.yml
fi
old_inventory_yml=$(basename -- $(readlink -f inventory.yml))
if [ "$inventory_yml" == "$old_inventory_yml" ] ; then
  echo "target env not updated"
else
  link_name=inventory.yml
  target=${secrets_dir}/${inventory_yml}
  if [ ! -L $link_name ] ; then
    echo "symlink not found: $link_name"
    exit 3
  fi
  rm $link_name
  if [ ! -f $target ] ; then
    echo "file not found: $target"
    exit 4
  fi
  ln -s $target $link_name
  if [ ! -d vars ] ; then
    echo "directory not found: vars"
    exit 5
  fi
  cd vars
  link_name=secrets.yml
  target=../${secrets_dir}/${secrets_yml}
  if [ ! -L $link_name ] ; then
    echo "symlink not found: vars/$link_name"
    exit 6
  fi
  rm $link_name
  if [ ! -f $target ] ; then
    echo "file not found: $target"
    exit 7
  fi
  ln -s $target $link_name
  cd ..
  echo "target env updated"
fi
