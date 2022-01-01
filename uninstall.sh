#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

script=$(readlink -f $0)
scriptPath=$(dirname $script)

systemctl stop tidal
systemctl disable tidal


# add old stretch repo for old debs
rm /etc/apt/sources.list.d/stretch.list
apt update

apt --yes purge multiarch-support libavformat57 libportaudio2 libflac++6v5 libavahi-common3 libavahi-client3 alsa-utils
apt --yes purge $scriptPath/deb/*
apt --yes autoremove

# blacklist 3.5mm analogue output
rm /etc/modprobe.d/blacklist-snd_bcm2835.conf

# blacklist HDMI audio out
rm /etc/modprobe.d/blacklist-vc4.conf

# rm proggy files
rm -rf /usr/ifi

# copy service file
rm /lib/systemd/system/tidal.service

echo "You should probably reboot"

