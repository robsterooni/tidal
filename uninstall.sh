#!/bin/bash

script=$(readlink -f $0)
scriptPath=$(dirname $script)

if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root : " 1>&2
  echo "sudo $0" 1>&2
  exit
fi


systemctl stop tidal-devices.timer
systemctl disable tidal-devices.timer

systemctl stop tidal-watchdog.timer
systemctl disable tidal-watchdog.timer

systemctl stop tidal.service


# add old stretch repo for old debs
rm /etc/apt/sources.list.d/stretch.list
apt update

#apt --yes purge multiarch-support libavformat57 libportaudio2 libflac++6v5 libavahi-common3 libavahi-client3 alsa-utils
#apt --yes purge $scriptPath/deb/*
#apt --yes autoremove

# blacklist 3.5mm analogue output
#rm /etc/modprobe.d/blacklist-snd_bcm2835.conf

# blacklist HDMI audio out
#rm /etc/modprobe.d/blacklist-vc4.conf

# rm proggy files
rm -rf /usr/ifi
rm /lib/systemd/system/tidal*
rm /usr/bin/tidal*
rm -rf /etc/tidal
rm -rf /var/tidal



