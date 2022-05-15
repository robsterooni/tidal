#!/bin/bash

script=$(readlink -f $0)
scriptPath=$(dirname $script)

configFile=/etc/tidal/config.json

if [ ! -f $configFile ]; then
    echo "<2>${configFile} doesnt exist, leaving" 1>&2
    exit 8
fi

name=$(jq --raw-output '.name' $configFile)
codecMPEGH=$(jq --raw-output '.codecMPEGH' $configFile)
codecMQA=$(jq --raw-output '.codecMQA' $configFile)
passthroughMQA=$(jq --raw-output '.passthroughMQA' $configFile)


echo "<6>config : name($name)"
echo "<6>config : codecMPEGH($codecMPEGH)"
echo "<6>config : codecMQA($codecMQA)"
echo "<6>config : passthroughMQA($passthroughMQA)"

/usr/ifi/ifi-tidal-release/bin/tidal_connect_application \
  --tc-certificate-path "/usr/ifi/ifi-tidal-release/id_certificate/IfiAudio_ZenStream.dat" \
  --friendly-name "$name" \
  --codec-mpegh $codecMPEGH \
  --codec-mqa $codecMQA \
  --model-name "$name" \
  --disable-app-security false \
  --disable-web-security false \
  --enable-mqa-passthrough $passthroughMQA \
  --log-level 3 \
  --enable-websocket-log "0" \
  --playback-device "default"

