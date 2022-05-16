#!/bin/bash



trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}



DialogOption() {
  options=()
  choices=("$@")

  i=0
  for choice in "${choices[@]}"; do
    options+=("$i")
    options+=("$choice")
    if [ $i -eq 0 ]; then
      options+=("on")
    else
      options+=("off")
    fi
    ((i=i+1))
  done

  index=$(dialog --stdout --no-cancel --no-tags --no-collapse --radiolist "Choose :" 0 0 0 "${options[@]}")
  echo "${choices[$index]}"
}


Start() {
  systemctl --quiet enable tidal
  systemctl --quiet start tidal
}


Stop() {
  systemctl --quiet stop tidal
  systemctl --quiet disable tidal
}


Restart() {
  Stop
  Start
}


ConfigFileALSA() {
  echo "/etc/alsa/conf.d/tidal.conf"
}
ConfigFileTidal() {
  echo "/etc/tidal/config.json"
}


ConfigureALSA() {
  Stop

  alsaconf=$(ConfigFileALSA)

  cardFolders=$(ls -d /proc/asound/* | grep -e '/proc/asound/card[0-9]')
  cards=()
  for card in $cardFolders; do
    cards+=($(cat $card/id))
  done
  card=$(DialogOption ${cards[@]})

  mv $alsaconf /etc/alsa/conf.d.backup/tidal.conf_$(date --iso-8601=seconds)

  formats_raw=$(aplay -D hw:${card},0 /dev/zero --dump-hw-params -s 1  2>&1 | grep -e "^FORMAT:" | cut -f2 -d ":")
  formats_raw=$(trim $formats_raw)
  formats=()
  for f in $formats_raw; do
    formats+=($f)
  done
  format=$(DialogOption ${formats[@]})

  cat << EOF > $alsaconf
pcm.!default {
  type plug
  slave {
    pcm "hw:${card},0"
    format ${format}
  }
}
EOF

  Start
}



ConfigureTidal() {
  Stop

  name=$(dialog --stdout --no-cancel --inputbox "Name :" 0 0)

  dialog --stdout --yesno "Decode MPEGH :" 0 0
  [[ $? = 0 ]] && codecMPEGH="true" || codecMPEGH="false"

  dialog --stdout --yesno "Decode MQA :" 0 0
  [[ $? = 0 ]] && codecMQA="true" || codecMQA="false"

  dialog --stdout --default-button "no" --yesno "Passthrough MQA :" 0 0
  [[ $? = 0 ]] && passthroughMQA="true" || passthroughMQA="false"

  jo -p \
    name="${name}" \
    codecMPEGH=$codecMPEGH \
    codecMQA=$codecMQA \
    passthroughMQA=$passthroughMQA \
    > /etc/tidal/config.json


  Start
  return 0
}




MainMenu() {
  ip=$(trim $(hostname -I))

  msg=""

  active=$(systemctl is-active tidal.service)
  enabled=$(systemctl is-enabled tidal.service)
  msg+="Tidal Service   : ${active} / ${enabled} "$'\n'
  msg+=$'\n'

  configFileTidal=$(ConfigFileTidal)
  if [ -f $configFileTidal ] ; then
    name=$(jq --raw-output '.name' $configFileTidal)
    codecMPEGH=$(jq --raw-output '.codecMPEGH' $configFileTidal)
    codecMQA=$(jq --raw-output '.codecMQA' $configFileTidal)
    passthroughMQA=$(jq --raw-output '.passthroughMQA' $configFileTidal)

    msg+="Tidal config (${configFileTidal}) : "$'\n'
    msg+="Name            : $name"$'\n'
    msg+="Decode MPEGH    : $codecMPEGH"$'\n'
    msg+="Decode MQA      : $codecMQA"$'\n'
    msg+="Passthrough MQA : $passthroughMQA"$'\n'
  else
    msg+="Tidal config (${configFileTidal}) : NOT found"$'\n'
  fi
  msg+=$'\n'


  configFileALSA=$(ConfigFileALSA)
  if [ -f $configFileALSA ] ; then
    msg+="ALSA config (${configFileALSA}) : "$'\n'
    msg+=$(cat $configFileALSA)
  else
    msg+="ALSA config (${configFileALSA}) : NOT found"$'\n'
  fi



  result=$(dialog --stdout \
    --backtitle "IP(${ip}) : Tidal Connect Configuration Utility" \
    --no-collapse  --default-item 5 --no-cancel \
    --menu "$msg" 0 0 0 \
    1 "Configure Tidal" \
    2 "Configure ALSA" \
    3 "Start Services" \
    4 "Stop Services" \
    5 "Refresh Status" \
    6 "Exit" \
    )

  case $result in
	1) ConfigureTidal;;
	2) ConfigureALSA;;
	3) Start;;
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




