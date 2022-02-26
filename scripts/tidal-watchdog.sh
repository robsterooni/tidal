#!/bin/bash


StopTidal() {
  systemctl is-active --quiet tidal
  if [ $? -eq 0 ]; then
    echo "<5>Stopping Tidal"
    systemctl stop tidal
  fi
}


StartTidal() {
  systemctl is-active --quiet tidal
  if [ $? -ne 0 ]; then
    echo "<5>Starting Tidal"
    systemctl start tidal
  fi
}


if [[ $EUID -ne 0 ]]; then
    echo "<2>This script must be run as root" 1>&2
    exit 1
fi


configFile=/etc/tidal/config.json
if [ ! -f $configFile ] ; then
  echo "${configFile} NOT found" > /var/tidal/tidal-watchdog.status
  echo "<2>configFile(${configFile}) does not exist" 1>&2
  StopTidal
  exit 2
fi


devicesFile=/var/tidal/devices.json
if [ ! -f $devicesFile ] ; then
  echo "<6>devicesFile(${devicesFile}) does not exist, you may have no devices connected"
  echo "no devices found" > /var/tidal/tidal-watchdog.status
  StopTidal
  exit 0
fi
devices=$(jq -r '.[]' < $devicesFile)


desiredPlaybackDevice=$(jq --raw-output '.playbackDevice' $configFile)

while read line; do
  if [[ $line == $desiredPlaybackDevice ]]; then
    echo "${desiredPlaybackDevice} found" > /var/tidal/tidal-watchdog.status
    StartTidal
    exit 0
  fi
done <<< "$devices"


echo "<6>desiredPlaybackDevice($desiredPlaybackDevice) is not connected"
echo "${desiredPlaybackDevice} NOT found" > /var/tidal/tidal-watchdog.status
StopTidal

exit 0

