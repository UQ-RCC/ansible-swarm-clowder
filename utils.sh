#!/bin/bash

set -e

env=dev
master=0
slave=0
xxapi=0
roles="master slave"
update=0
autorm=0
reboot=0
uptime=0
mount=0
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
  echo "usage: $0 [-p|--prod] [-m|--master-only] [-s|--slave-only] [-x|--xxapi]"
  echo "       [-u|--update] [-v|--auto-remove] [-b|--reboot] [--uptime] [-d|--mount]"
  echo "       [-t|--image-tag <tag>] [-r|--image-tag-rm]"
  echo "       [-a|--image-tar <tar>] [-l|--load] [-o|--no-scp] [-p|--no-tar-rm]"
  echo "       [--gfs [stop|start|status]]"
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
    -u|--update)
      update=1
      shift
      ;;
    -v|--auto-remove)
      autorm=1
      shift
      ;;
    -b|--reboot)
      reboot=1
      shift
      ;;
    --uptime)
      uptime=1
      shift
      ;;
    -d|--mount)
      mount=1
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
    --gfs)
      shift
      gfs_cmd=$1
      if [ -z "${gfs_cmd}" ] ; then
        echo gfs service command required
        usage
      fi
      shift
      ;;
    *)
      echo "unknown argument: $1"
      usage
      ;;
  esac
done

if [ -n "${gfs_cmd}" ] ; then
  if [[ ${gfs_cmd} =~ (start|stop) ]] ; then
    echo "=== ${env}-slave0 ==="
    read -p "${gfs_cmd} ${env} gfs service (y/n)? " resp
    if [[ $resp =~ ^(y|Y) ]] ; then
      if [ "${gfs_cmd}" = "stop" ] ; then
        ssh ${env}-slave0 sudo gluster --mode=script volume ${gfs_cmd} gfs
      else
        ssh ${env}-slave0 sudo gluster volume ${gfs_cmd} gfs
      fi
    fi
  elif [ "${gfs_cmd}" = "status" ] ; then
    echo "=== ${env}-slave0 ==="
    ssh ${env}-slave0 sudo gluster volume ${gfs_cmd} gfs
  else
    echo "unknown gfs service command: ${gfs_cmd}"
    usage
  fi
  exit
fi

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

if [ $mount -eq 1 ] ; then
  env=dev
  roles=slave
  xxapi=0
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
    if [ $update -eq 1 ] ; then
      ssh ${host} 'sudo apt update && sudo apt full-upgrade -y'
    fi
    if [ ${autorm} -eq 1 ] ; then
      ssh ${host} 'sudo apt auto-remove -y'
    fi
    if [ $reboot -eq 1 ] ; then
      ssh ${host} 'sudo systemctl reboot'
    fi
    if [ $uptime -eq 1 ] ; then
      ssh ${host} 'uptime'
    fi
    if [ $mount -eq 1 ] ; then
      ssh ${host} 'sudo ./mnt_data.sh'
    fi
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
