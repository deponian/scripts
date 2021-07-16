#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# source of this script is https://superuser.com/questions/919033/quickly-change-audio-device-in-kde/921579
# thanks to linuxkd for that

# Audio sinks
headset='alsa_output.pci-0000_00_1f.3.iec958-stereo'
speakers='alsa_output.pci-0000_00_1f.3.analog-stereo'

# Get current audio sink
currentdev="$(pactl list short sinks | grep RUNNING | awk \{'print $2'\})"

# Determine our next audio sink
if [[ "${currentdev}" == "${headset}" ]]; then
    nextdev="${speakers}"
else
    nextdev="${headset}"
fi

# Set our default device
pactl set-default-sink "${nextdev}"

# Move current streams (dont check for null, if null you wont see heads up display of audio change)
inputs=("$(pacmd list-sink-inputs | grep index | awk '{print $2}')")
for stream in ${inputs[*]}; do
	pacmd move-sink-input "${stream}" "${nextdev}" &> /dev/null;
done
