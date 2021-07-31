#!/bin/bash
set -euo pipefail
set -x
IFS=$'\n\t'

# this script is based on https://superuser.com/questions/919033/quickly-change-audio-device-in-kde/921579
# thanks to linuxkd for that

# Audio profiles
headset="output:iec958-stereo"
speakers="output:analog-stereo"
# Card index
card_index="3"

# Change current audio profile
if pacmd list-cards | grep 'active profile' | grep -q "${speakers}"; then
	pactl set-card-profile "${card_index}" "${headset}"
else
	pactl set-card-profile "${card_index}" "${speakers}"
fi
