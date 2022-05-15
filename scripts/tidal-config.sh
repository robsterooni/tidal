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



Configure() {

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

  cardFolders=$(ls -d /proc/asound/* | grep -e '/proc/asound/card[0-9]')
  cards=()
  for card in $cardFolders; do
    cards+=($(cat $card/id))
  done
  card=$(DialogOption ${cards[@]})

  mv /etc/asound.conf /etc/asound.conf.tmp
  formats_raw=$(aplay -D hw:${card},0 /dev/zero --dump-hw-params -s 1  2>&1 | grep -e "^FORMAT:" | cut -f2 -d ":")
  mv /etc/asound.conf.tmp /etc/asound.conf

  formats_raw=$(trim $formats_raw)
  formats=()
  for f in $formats_raw; do
    formats+=($f)
  done
  format=$(DialogOption ${formats[@]})

  mv /etc/asound.conf /etc/asound.conf.bak_$(date --iso-8601=seconds)
  cat << EOF > /etc/asound.conf
pcm.!default {
  type plug
  slave {
    pcm "hw:${card},0"
    format ${format}
  }
}
EOF

  return 0
}




MainMenu() {
  ip=$(trim $(hostname -I))

  msg=""
  configFile=/etc/tidal/config.json
  if [ -f $configFile ] ; then
    name=$(jq --raw-output '.name' $configFile)
    codecMPEGH=$(jq --raw-output '.codecMPEGH' $configFile)
    codecMQA=$(jq --raw-output '.codecMQA' $configFile)
    passthroughMQA=$(jq --raw-output '.passthroughMQA' $configFile)

    msg+="Name            : $name"$'\n'
    msg+="Decode MPEGH    : $codecMPEGH"$'\n'
    msg+="Decode MQA      : $codecMQA"$'\n'
    msg+="Passthrough MQA : $passthroughMQA"$'\n'
  else
    msg+="No configuration found!"$'\n'
  fi

  active=$(systemctl is-active tidal.service)
  enabled=$(systemctl is-enabled tidal.service)
  msg+="Tidal Service   : ${active} / ${enabled} "$'\n'
  msg+=$'\n'
  msg+="ALSA config (/etc/asound.conf) : "$'\n'
  msg+=$(cat /etc/asound.conf)

  result=$(dialog --stdout \
    --backtitle "IP(${ip}) : Tidal Connect Configuration Utility" \
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




