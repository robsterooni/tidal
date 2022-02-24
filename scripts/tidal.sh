#!/bin/bash

script=$(readlink -f $0)
scriptPath=$(dirname $script)

jsonConfig=/etc/tidal/config.json

if [ ! -f $jsonConfig ]; then
    echo "<2>${jsonConfig} doesnt exist, leaving" 1>&2
    exit 8
fi

modelName=$(jq --raw-output '.modelName' $jsonConfig)
friendlyName=$(jq --raw-output '.friendlyName' $jsonConfig)
codecMPEGH=$(jq --raw-output '.codecMPEGH' $jsonConfig)
codecMQA=$(jq --raw-output '.codecMQA' $jsonConfig)
passthroughMQA=$(jq --raw-output '.passthroughMQA' $jsonConfig)
playbackDevice=$(jq --raw-output '.playbackDevice' $jsonConfig)


echo "<6>config : modelName($modelName)"
echo "<6>config : friendlyName($friendlyName)"
echo "<6>config : codecMPEGH($codecMPEGH)"
echo "<6>config : codecMQA($codecMQA)"
echo "<6>config : passthroughMQA($passthroughMQA)"
echo "<6>config : playbackDevice($playbackDevice)"

/usr/ifi/ifi-tidal-release/bin/tidal_connect_application \
  --tc-certificate-path "/usr/ifi/ifi-tidal-release/id_certificate/IfiAudio_ZenStream.dat" \
  --friendly-name "$friendlyName" \
  --codec-mpegh $codecMPEGH \
  --codec-mqa $codecMQA \
  --model-name "$modelName" \
  --disable-app-security false \
  --disable-web-security false \
  --enable-mqa-passthrough true \
  --log-level 3 \
  --enable-websocket-log "0" \
  --playback-device "$playbackDevice"








