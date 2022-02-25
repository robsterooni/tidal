#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "<2>This script must be run as root" 1>&2
    exit 1
fi

configFile=/etc/tidal/config.json
devicesFile=/var/tidal/devices.json

if [ ! -f $configFile ] ; then
  echo "<2>configFile(${configFile}) does not exist, stopping tidal and leaving with error" 1>&2
  systemctl stop tidal
  exit 2
fi

if [ ! -f $devicesFile ] ; then
  echo "<5>devicesFile(${devicesFile}) does not exist, you may have no devices connected.  stopping tidal and leaving without error" 1>&2
  systemctl stop tidal
  exit 0
fi

playbackDevice=$(jq --raw-output '.playbackDevice' $configFile)

devices=$(jq -r '.[]' < $devicesFile)

while read line; do
  if [[ $line == $playbackDevice ]]; then
    echo "<6>Yes! Found configured playbackDevice($playbackDevice), starting tidal and leaving without error (it might already be running, btw)"
    systemctl start tidal
    exit 0
  fi
done <<< "$devices"

echo "<5>We got this far without finding configured playbackDevice($playbackDevice) currently connected, stopping tidal and leaving without error"
systemctl stop tidal
exit 0

