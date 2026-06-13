#!/bin/sh
cd ~/git/arrpc/
pkill -9 arrpc
pkill -9 node
pkill -9 flatpak
npx arrpc
