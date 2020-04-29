#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

#
# run your command after unlock XFCE session
#

session=/org/freedesktop/login1/session/$XDG_SESSION_ID
iface=org.freedesktop.login1.Session
dbus-monitor --system "type=signal,path=$session,interface=$iface" 2>/dev/null |
	while read -r signal stamp sender arrow dest rest; do
	case "$rest" in
		*Unlock)
			echo "Your command here"
		;;  #unknown Session signal received
		*)
			echo "$signal" "$stamp" "$sender" "$arrow" "$dest" "$rest"
	esac
done
