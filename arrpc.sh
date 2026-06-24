#!/bin/sh
sleep 3
pkill -9 flatpak
pkill -9 arrpc
pkill -9 node
pkill -9 flatpak
sleep 1
npx arrpc
