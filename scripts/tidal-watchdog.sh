#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "<2>This script must be run as root" 1>&2
    exit 1
fi

configFile=/etc/tidal/config.json
devicesFile=/var/tidal/devices.json

if [ ! -f $configFile ] ; then
  if [ $? -eq 0 ]; then
    echo "<2>configFile(${configFile}) does not exist.  Tidal is running and it needs to stop" 1>&2
    systemctl stop tidal
  fi
  systemctl stop tidal
  exit 2
fi

if [ ! -f $devicesFile ] ; then
  if [ $? -eq 0 ]; then
    echo "<3>devicesFile(${devicesFile}) does not exist, you may have no devices connected.  Tidal is running and it needs to stop" 1>&2
    systemctl stop tidal
  fi
  exit 0
fi

playbackDevice=$(jq --raw-output '.playbackDevice' $configFile)

devices=$(jq -r '.[]' < $devicesFile)

while read line; do
  if [[ $line == $playbackDevice ]]; then
    systemctl is-active --quiet tidal
    if [ $? -ne 0 ]; then
      echo "<5>Tidal is not currently running and it needs to start, running with playbackDevice($playbackDevice)"
      systemctl start tidal
    fi
    exit 0
  fi
done <<< "$devices"


if [ $? -eq 0 ]; then
  echo "<5>playbackDevice($playbackDevice) is not connected.  Tidal is running and it needs to stop"
  systemctl stop tidal
fi

exit 0

