
This should be installed on a CLEAN Raspberry Pi OS Lite 32-bit (debian Bullseye).  This is tested on a Pi4 with a NAD Amp and a Chord Mojo 2 - both over USB.  The analog 3.5mm onboard analg output works but sounds poor.   To get working with Allo DigiOne, add "dtoverlay=allo-digione"  to /boot/config.txt and reboot


**To Install :**

sudo apt --yes install git

git clone https://github.com/robsterooni/tidal

sudo ./tidal/install.sh

