#!/bin/bash

seconds_left=$((60 - $(date +%S)))
printf "%d\n" $seconds_left
