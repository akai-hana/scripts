#!/bin/sh
# Launches osu along with OTD, cleans OTD up when exiting osu

# launch osu and OTD
flatpak run sh.ppy.osu &
OSU_PID=$!
flatpak run net.opentabletdriver.OpenTabletDriver &

# set real-time priority
sleep 1s
doas chrt -f -p 99 $(ps -e | grep OpenTabletDrive | awk '{print $1}')

# clean-up
wait $OSU_PID
pkill OpenTabletDriver
