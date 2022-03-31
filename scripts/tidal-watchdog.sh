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


while true
do
  sleep 3

  configFile=/etc/tidal/config.json
  if [ ! -f $configFile ] ; then
    echo "${configFile} NOT found" > /var/tidal/tidal-watchdog.status
    echo "<2>configFile(${configFile}) does not exist" 1>&2
    StopTidal
    continue
  fi


  devices=$(tidal-devices-hw.sh | jq -r '.[]')
#  echo "devices(${devices})"

  desiredPlaybackDevice=$(jq --raw-output '.playbackDevice' $configFile)
  desiredPlaybackDevice=$(echo "$desiredPlaybackDevice" | awk '{split($0,a,":"); print a[1];}')
  echo "<6>desiredPlaybackDevice(${desiredPlaybackDevice})"

  while read line; do
    if [[ $line == $desiredPlaybackDevice ]]; then
      echo "<6>[$desiredPlaybackDevice] is connected"
      echo "[${desiredPlaybackDevice}] found" > /var/tidal/tidal-watchdog.status
      StartTidal
      continue 2
    fi
  done <<< "$devices"


  echo "<6>[$desiredPlaybackDevice] is not connected"
  echo "[${desiredPlaybackDevice}] NOT found" > /var/tidal/tidal-watchdog.status
  StopTidal
done



