#!/bin/bash

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

# copy service file
cp $scriptPath/tidal.service /lib/systemd/system/

# override default service file with NAD amp settings
mkdir -p /etc/systemd/system/tidal.service.d/
cat << EOF > /etc/systemd/system/tidal.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/ifi/ifi-tidal-release/bin/tidal_connect_application \
   --tc-certificate-path "/usr/ifi/ifi-tidal-release/id_certificate/IfiAudio_ZenStream.dat" \
   --friendly-name "NAD" \
   --codec-mpegh true \
   --codec-mqa true \
   --model-name "NAD" \
   --disable-app-security false \
   --disable-web-security false \
   --enable-mqa-passthrough true \
   --log-level 3 \
   --enable-websocket-log "0" \
   --playback-device "NAD USB Audio: - (hw:1,0)"
EOF

systemctl daemon-reload
systemctl enable tidal
systemctl start tidal


echo "You should probably reboot"

