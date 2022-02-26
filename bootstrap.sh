#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root : " 1>&2
  echo "sudo $0" 1>&2
  exit
fi

script=$(readlink -f $0)
scriptPath=$(dirname $script)

bld=$(mktemp -d)
cd $bld
git clone https://github.com/robsterooni/tidal

$bld/tidal/install.sh
