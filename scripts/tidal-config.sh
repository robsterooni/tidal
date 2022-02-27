#!/bin/bash



trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}


Start() {
  systemctl start tidal-watchdog.timer
  dialog --timeout 2 --no-cancel  --pause "Starting Services" 10 0 3
}

Stop() {
  systemctl stop tidal-watchdog.timer
  systemctl stop tidal
  rm -f /var/tidal/tidal-watchdog.status
  dialog --timeout 2 --no-cancel  --pause "Stopping Services" 10 0 3
}

Restart() {
  Stop
  Start
}



Configure() {
  modelName=$(dialog --stdout --no-cancel --inputbox "Model Name :" 0 0)
  friendlyName=$(dialog --stdout --no-cancel --inputbox "Friendly Name :" 0 0)

  dialog --stdout --yesno "Decode MPEGH :" 0 0
  [[ $? = 0 ]] && codecMPEGH="true" || codecMPEGH="false"

  dialog --stdout --yesno "Decode MQA :" 0 0
  [[ $? = 0 ]] && codecMQA="true" || codecMQA="false"

  dialog --stdout --default-button "no" --yesno "Passthrough MQA :" 0 0
  [[ $? = 0 ]] && passthroughMQA="true" || passthroughMQA="false"

 
  devices=$(tidal-devices.sh | jq -r '.[]')
  devices=$(trim "$devices")

  i=0
  if [ ! -z "$devices" ]; then
    deviceOptions=()
    deviceArray=()
    while read line; do
      deviceArray+=("$line")
      deviceOptions+=("$i")
      deviceOptions+=("$line")
      if [ $i -eq 0 ]; then
        deviceOptions+=("on")
      else
        deviceOptions+=("off")
      fi
      ((i=i+1))
    done <<< "$devices"

    playbackDeviceIndex=$(dialog --stdout --no-cancel --no-tags --no-collapse --radiolist "Playback Device :" 0 0 0 "${deviceOptions[@]}")
    playbackDevice="${deviceArray[$playbackDeviceIndex]}"

    jo -p \
      modelName="${modelName}" \
      friendlyName="${friendlyName}" \
      codecMPEGH=$codecMPEGH \
      codecMQA=$codecMQA \
      passthroughMQA=$passthroughMQA \
      playbackDevice="${playbackDevice}" > /etc/tidal/config.json

    dialog --msgbox "Configuration written to /etc/tidal/config.json" 0 0
    Restart
    return 0
  else
    dialog --msgbox "No devices found, configuration NOT changed" 0 0
    return 1
  fi
}



MainMenu() {
  msg=$'Status : System Information\n---------------------------\n'
  ip=$(hostname -I)
  msg+="IP : $ip"$'\n'
  msg+=$'\n'


  msg+=$'Status : Playback Devices\n-------------------------\n'

  devices=$(tidal-devices.sh | jq -r '.[]')
  devices=$(trim "$devices")

  if [ -z "$devices" ] ; then
    msg+="No devices found!"$'\n'
  else
    msg+=$devices
  fi
  msg+=$'\n\n'

  msg+=$'Status : Current Configuration\n------------------------------\n'
  configFile=/etc/tidal/config.json
  if [ -f $configFile ] ; then
    modelName=$(jq --raw-output '.modelName' $configFile)
    friendlyName=$(jq --raw-output '.friendlyName' $configFile)
    codecMPEGH=$(jq --raw-output '.codecMPEGH' $configFile)
    codecMQA=$(jq --raw-output '.codecMQA' $configFile)
    passthroughMQA=$(jq --raw-output '.passthroughMQA' $configFile)
    playbackDevice=$(jq --raw-output '.playbackDevice' $configFile)

    msg+="Model Name      : $modelName"$'\n'
    msg+="Friendly Name   : $friendlyName"$'\n'
    msg+="Decode MPEGH    : $codecMPEGH"$'\n'
    msg+="Decode MQA      : $codecMQA"$'\n'
    msg+="Passthrough MQA : $passthroughMQA"$'\n'
    msg+="Playback Device : $playbackDevice"$'\n'
  else
    msg+="No configuration found!"$'\n'
  fi
  msg+=$'\n'

  msg+=$'Status : Services\n-----------------\n'
  watchdogStatus=$(cat /var/tidal/tidal-watchdog.status)
  msg+="Tidal                 : "$(systemctl is-active tidal.service)$'\n'
  msg+="Tidal Watchdog        : "$(systemctl is-active tidal-watchdog.timer)$'\n'
  msg+="Tidal Status          : ${watchdogStatus}"$'\n'
  msg+=$'\n\n'


  result=$(dialog --stdout \
    --backtitle "Tidal Connect Configuration Utility" \
    --no-collapse  --default-item 5 --no-cancel \
    --menu "$msg" 0 0 0 \
    1 "Configure" \
    2 "Start Services" \
    3 "Restart Services" \
    4 "Stop Services" \
    5 "Refresh Status" \
    6 "Exit" \
    )

  case $result in
	1) Configure;;
	2) Start;;
	3) Restart;;
	4) Stop;;
	5) ;;
	6) ;;
  esac

  return $result
}



if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root :" 1>&2
    echo "  sudo $0" 1>&2
    exit 1
fi



while : ; do
  MainMenu
  if [ $? -eq 6 ]; then
    break;
  fi
done
clear

echo "To run Tidal Configuration Utility again, run :"
echo "  sudo $0"




