#!/bin/bash

set -e

env=dev
master=0
slave=0
xxapi=0
roles="master slave"
image_tag="uqrcc/clowder:pitschi1.20.7"
#image_tag="uqrcc/pitschi-xapi:1.9.4"
image_tag_rm=0
image_tar="../clowder/clowder_1_20_7.tar"
#image_tar="../pitschi-xapi/pitschi-xapi_1_9_4.tar"
image_tar_load=0
image_tar_cp=-1
image_tar_rm=-1
gfs_cmd=""

usage() {
  echo "usage: $0 \\"
  echo "         [-t|--image-tag <tag>] \\"
  echo "         [-r|--image-tag-rm]"
  echo "         [-a|--image-tar <tar>] \\"
  echo "         [-l|--load] [-o|--no-scp] \\"
  echo "         [-p|--no-tar-rm]"
  exit -1
}

while [[ $# -gt 0 ]] ; do
  case $1 in
    -p|--prod)
      env=stage6
      shift
      ;;
    -m|--master-only)
      master=1
      shift
      ;;
    -s|--slave-only)
      slave=1
      shift
      ;;
    -x|--xxapi)
      roles=xxapi
      xxapi=1
      shift
      ;;
    -t|--image-tag)
      shift
      image_tag=$1
      if [ -z "${image_tag}" ] ; then
        echo docker image tag required
        usage
      fi
      shift
      ;;
    -r|--image-tag-rm)
      image_tag_rm=1
      shift
      ;;
    -a|--image-tar)
      shift
      image_tar=$1
      if [ -z "${image_tar}" ] ; then
        echo docker image tar file required
        usage
      fi
      shift
      ;;
    -l|--load)
      image_tar_load=1
      shift
      ;;
    -o|--no-scp)
      image_tar_cp=0
      shift
      ;;
    -p|--no-tar-rm)
      image_tar_rm=0
      shift
      ;;
    *)
      echo "unknown argument: $1"
      usage
      ;;
  esac
done

if [ $master -eq 1 ] && [ $slave -eq 0 ] ; then
  roles="master"
  xxapi=0
elif [ $master -eq 0 ] && [ $slave -eq 1 ] ; then
  roles="slave"
  xxapi=0
fi

if [ $image_tag_rm -eq 1 ] && [ $image_tar_rm -eq -1 ] ; then
  image_tar_rm=1
else
  image_tar_rm=0
fi

if [ $image_tar_load -eq 1 ] && [ $image_tar_cp -eq -1 ] ; then
  image_tar_cp=1
else
  image_tar_cp=0
fi

for role in ${roles} ; do
  for i in 0 1 2 ; do
    if [ ${xxapi} -eq 1 ] ; then
      if [ ${i} -eq 0 ] ; then
        continue
      fi
      host=${role}${i}
    else
      host=${env}-${role}${i}
    fi
    echo "=== ${host} ==="
    if [ $image_tar_rm -eq 1 ] ; then
      ssh ${host} 'rm -fv "'${image_tar##*/}'"'
    fi
    if [ $image_tag_rm -eq 1 ] ; then
      ssh ${host} 'docker image rm "'${image_tag}'"'
    fi
    if [ $image_tar_cp -eq 1 ] ; then
      scp ${image_tar} ${host}:
    fi
    if [ $image_tar_load -eq 1 ] ; then
      ssh ${host} 'docker load -i "'${image_tar##*/}'"'
    fi
  done
done
