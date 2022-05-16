#!/bin/bash

script=$(readlink -f $0)
scriptPath=$(dirname $script)

if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root : " 1>&2
  echo "sudo $0" 1>&2
  exit
fi


systemctl stop    tidal
systemctl disable tidal


# add old stretch repo for old debs
rm /etc/apt/sources.list.d/stretch.list
apt update


# rm proggy files
rm -rf /usr/ifi
rm /lib/systemd/system/tidal*
rm /usr/bin/tidal*
rm -rf /etc/tidal
rm -f /etc/alsa/conf.d/*tidal*.conf



