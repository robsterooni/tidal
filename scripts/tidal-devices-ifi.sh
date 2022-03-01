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

rawDevices=$(/usr/ifi/ifi-tidal-release/pa_devs/bin/ifi-pa-devs-get 2> /dev/null)

devices=""
while read line; do
  if [[ $line == device#* ]]; then
    if [[ $line =~  ^device#[0-9]*=.*\(hw:[0-9]*,[0-9]*\)$ ]]; then
      trimmer=$(cut -d "=" -f2 <<< "$line")
      devices+="$trimmer"
      devices+=$'\n'
    fi
  fi
done <<< "$rawDevices"

devices=$(trim "$devices")

if [ -z "$devices" ]; then
    exit 1
fi

echo "$devices" | jo -a









