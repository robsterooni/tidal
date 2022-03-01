#!/bin/bash

trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   
    printf '%s' "$var"
}


rawDevices=$(aplay -l)
devices=""
while read line; do
  if [[ $line == card* ]]; then
    card=$(echo "$line" | awk '{print $2}' | grep --only-matching --extended-regexp '[0-9]' )
    names=$(echo "$line" |  grep -Po "(\[.+?\])" | tr -d "[]")
    name1=$(sed -n 1p <<< "$names")
    name2=$(sed -n 2p <<< "$names")
#    if [ "$name1" = "bcm2835 Headphones" ]; then
#      name2="-"
#    fi
#    if [[ $name1 != vc4-hdmi* ]]; then
#      devices+="${name1}: ${name2} (hw:${card},0)"$'\n'
#    fi
    devices+="${name1}"$'\n'
  fi
done <<< "$rawDevices"

devices=$(trim "$devices")

if [ -z "$devices" ]; then
    exit 1
fi

echo "$devices" | jo -a









