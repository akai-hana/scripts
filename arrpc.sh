#!/bin/sh
sleep 3

cd ~/git/arrpc/
pkill -9 arrpc
pkill -9 node
pkill -9 flatpak
npx arrpc
