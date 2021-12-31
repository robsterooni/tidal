#!/bin/bash

apt --yes install /usr/share/tidal/*.deb

cat << EOF > /etc/modprobe.d/blacklist-snd_bcm2835.conf
blacklist snd_bcm2835
EOF

# blacklist HDMI audio out
cat << EOF > /etc/modprobe.d/blacklist-vc4.conf
blacklist vc4
EOF

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
systemctl restart tidal

echo "You should probably reboot"

