#!/bin/bash

device=/sys/devices/platform/scb/fd500000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0/usb1/1-1/1-1.2/1-1.2:1.0/sound/card1/controlC1

if [ -d "${device}" ]; then
  systemctl start tidal;
else
  systemctl stop tidal;
fi



[Install]
WantedBy=multi-user.target






