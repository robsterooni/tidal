#!/bin/bash

trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   
    printf '%s' "$var"
}

if [[ $EUID -ne 0 ]]; then
    echo "<2>This script must be run as root" 1>&2
    exit 1
fi

configFile=/etc/tidal/config.json
devicesFile=/var/tidal/devices.json

if [ ! -f $configFile ] ; then
  echo "<2>configFile(${configFile}) does not exist, leaving" 1>&2
  exit 2
fi

rawDevices=$(/usr/ifi/ifi-tidal-release/pa_devs/bin/ifi-pa-devs-get 2> /dev/null)

devices=""
while read line; do
  if [[ $line == device#* ]]; then
    trimmer=$(cut -d "=" -f2 <<< "$line")
    devices+="$trimmer"
    devices+=$'\n'
  fi
done <<< "$rawDevices"

devices=$(trim "$devices")

if [ -z "$devices" ]; then
#  echo "<6> No devices found, removing $devicesFile"
  rm -f $devicesFile
else
  echo "$devices" | jo -a > $devicesFile
fi









