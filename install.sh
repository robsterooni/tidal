#!/bin/bash

script=$(readlink -f $0)
scriptPath=$(dirname $script)

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root : " 1>&2
  echo "sudo $0" 1>&2
  exit
fi

# add old stretch repo for old debs
cat << EOF > /etc/apt/sources.list.d/stretch.list
deb http://archive.raspbian.org/raspbian stretch main
EOF

apt update
if [ $? -ne 0 ]; then
  echo "apt update failed" 1>&2
  exit 1
fi


apt --yes install jo jq \
  multiarch-support libavformat57 libportaudio2 libflac++6v5 \
  libavahi-common3 libavahi-client3 alsa-utils dialog \
  $scriptPath/deb/*
if [ $? -ne 0 ]; then
  echo "apt install of packages failed" 1>&2
  exit 1
fi


# copy prog files
mkdir -p /usr/ifi
cp -r $scriptPath/ifi-tidal-release /usr/ifi/

# copy service file
cp $scriptPath/services/* /lib/systemd/system/

# copy config file
mkdir -p /etc/tidal
mkdir -p /etc/alsa/conf.d
mkdir -p /etc/alsa/conf.d.backup

# copy scripts
cp $scriptPath/scripts/* /usr/bin/

systemctl daemon-reload

tidal-config.sh


