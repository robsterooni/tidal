#!/bin/bash



trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}


Configure() {
  modelName=$(dialog --stdout --inputbox "Model Name :" 0 0)
  friendlyName=$(dialog --stdout --inputbox "Friendly Name :" 0 0)

  dialog --stdout --yesno "Decode MPEGH :" 0 0
  [[ $? = 0 ]] && codecMPEGH="true" || codecMPEGH="false"

  dialog --stdout --yesno "Decode MQA :" 0 0
  [[ $? = 0 ]] && codecMQA="true" || codecMQA="false"

  dialog --stdout --default-button "no" --yesno "Passthrough MQA :" 0 0
  [[ $? = 0 ]] && passthroughMQA="true" || passthroughMQA="false"


  devicesFile=/var/tidal/devices.json
  devices=""
  if [ -f $devicesFile ] ; then
    devices=$(jq -r '.[]' < $devicesFile)
    devices=$(trim "$devices")
  fi

  i=0
  if [ ! -z "$devices" ]; then
    numDevices=$(echo $devices | wc -l)
    deviceOptions=()
    while read line; do
      ((i=i+1))
      deviceOptions+=("$i");
      deviceOptions+=("$line");
    done <<< "$devices"

   # echo "numDevices($i), deviceOptions( ${deviceOptions[@]} )"
   # exit 5

#    playbackDevice=$(dialog --stdout --menu "Playback Device :" 0 0 0 "${deviceOptions[@]}")
    dialog --stdout --menu "Playback Device :" 0 0 0 "${deviceOptions[@]}"
#    echo $paybackDevice;
    echo $?
    exit 5
  fi

  exit 3

}


MainMenu() {
  msg=$'Connected Playback Devices\n--------------------------\n'
  devicesFile=/var/tidal/devices.json
  if [ -f $devicesFile ] ; then
    devices=$(jq -r '.[]' < $devicesFile)
    msg+=$devices
  else
    msg+="No devices found!"
  fi
  msg+=$'\n\n'

  msg+=$'Current Configuration\n---------------------\n'
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
  fi
  msg+=$'\n\n'

  result=$(dialog --stdout \
    --default-button "no" \
    --no-label "Refresh" \
    --yes-label "Configure" \
    --yesno "$msg" 0 0)

  return $result
}



if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi


systemctl stop tidal-watchdog.timer
systemctl stop tidal



while : ; do
  MainMenu

  if [ $? -eq 0 ]; then
    Configure
    #break;
  fi

done



