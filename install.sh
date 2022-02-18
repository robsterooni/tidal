#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

script=$(readlink -f $0)
scriptPath=$(dirname $script)


# add old stretch repo for old debs
cat << EOF > /etc/apt/sources.list.d/stretch.list
deb http://archive.raspbian.org/raspbian stretch main
EOF
apt update

apt --yes install multiarch-support libavformat57 libportaudio2 libflac++6v5 libavahi-common3 libavahi-client3 alsa-utils
apt --yes install $scriptPath/deb/*


# blacklist 3.5mm analogue output
cat << EOF > /etc/modprobe.d/blacklist-snd_bcm2835.conf
blacklist snd_bcm2835
EOF

# blacklist HDMI audio out
cat << EOF > /etc/modprobe.d/blacklist-vc4.conf
blacklist vc4
EOF

# copy prog files
mkdir -p /usr/ifi
cp -r ifi-tidal-release /usr/ifi/

# copy service files
cp $scriptPath/services/tidal* /lib/systemd/system/

mkdir -p /etc/systemd/system/tidal.service.d/
cp $scriptPath/services/override/tidal-$1.conf /etc/systemd/system/tidal.service.d/override.conf

mkdir -p /etc/systemd/system/tidal-watchdog.service.d/
cp $scriptPath/services/override/tidal-watchdog-$1.conf /etc/systemd/system/tidal-watchdog.service.d/override.conf

systemctl daemon-reload
systemctl enable tidal-watchdog.timer
systemctl start  tidal-watchdog.timer

echo "You should probably reboot"

