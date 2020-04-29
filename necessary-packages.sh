#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

#
# install necessary packages for your distro
#

deb_packages () {
	local mode

	mode="${1:?"You have to specify mode as first parametr"}"
	apt update
	if [[ "${mode}" == "minimal" ]]; then
		apt install --no-install-recommends bash bc ccze dnsutils git htop iputils-ping mlocate \
			ncdu openssh-server rsync sudo tmux vim zsh
	elif [[ "${mode}" == "server" ]]; then
		apt install --no-install-recommends anacron apg apt-transport-https bash bc bridge-utils \
			bwm-ng ca-certificates ccze cron curl debsums dnsutils ethtool gdisk git gnupg2 htop \
			ifupdown iputils-ping ioping iotop iproute2 jid jq less links lsb-release lshw mc mlocate \
			mtr-tiny nano ncdu netcat nethogs netmask net-tools nmap openssh-server parted progress \
			rsync rsyslog strace sudo sysstat tcpdump telnet tmux traceroute unzip vim vlan wget \
			xz-utils zsh zstd
	elif [[ "${mode}" == "desktop" ]]; then
		apt install --no-install-recommends anacron apg apt-transport-https bash bc bridge-utils \
			bwm-ng ca-certificates ccze cron curl debsums dnsutils ethtool gdisk git gnupg2 htop \
			ifupdown iputils-ping ioping iotop iproute2 jid jq less links lsb-release lshw mc mlocate \
			mtr-tiny nano neovim ncdu netcat nethogs netmask net-tools nmap openssh-server parted \
			progress pylint python3-neovim rsync rsyslog strace sudo sysstat tcpdump telnet tmux \
			traceroute unzip vim vim-gui-common vlan wget xz-utils zsh zstd
	else
		echo "Something strange happened." >&2
	fi
}
# dnsutils -> bind-utils
# inetutils-ping -> iputils
# cron, anacron -> cronie cronie-anacron
rpm_packages () {
	local mode

	mode="${1:?"You have to specify mode as first parametr"}"
	if [[ "${mode}" == "minimal" ]]; then
		dnf --setopt=install_weak_deps=False install bash bc ccze bind-utils git htop iputils \
			mlocate ncdu openssh-server rsync sudo tmux vim zsh
	elif [[ "${mode}" == "server" ]]; then
		dnf --setopt=install_weak_deps=False install cronie-anacron apg bash bc bwm-ng ca-certificates \
			ccze cronie curl bind-utils ethtool gdisk git gnupg2 htop iputils ioping iotop jid jq less \
			links lshw mc mlocate mtr nano ncdu nethogs netmask net-tools nmap openssh-server \
			parted progress rsync rsyslog strace sudo sysstat tcpdump telnet tmux traceroute unzip vim wget \
			xz zsh zstd
	elif [[ "${mode}" == "desktop" ]]; then
		dnf --setopt=install_weak_deps=False install cronie-anacron apg bash bc bwm-ng ca-certificates \
			ccze cronie curl bind-utils ethtool gdisk git gnupg2 htop iputils ioping iotop jid jq less links \
			lshw mc mlocate mtr nano neovim ncdu nethogs netmask net-tools nmap openssh-server parted progress \
			pylint python3-neovim rsync rsyslog strace sudo sysstat tcpdump telnet tmux traceroute unzip \
			vim wget xz zsh zstd
	else
		echo "Something strange happened." >&2
	fi
}

main () {
	if [[ "$EUID" != 0 ]]
	then
		echo "Please run as root" >&2
		exit 1
	fi

	mode="${1:-}"
	while true; do
		if [[ "${mode}" =~ ^(minimal|server|desktop)$ ]]; then
			break
		else
			read -r -p 'Incorrect mode. Choose packages mode from "minimal", "server" and "desktop": ' mode
		fi
	done

	os_id="$(sed -n -E -e 's/^ID=(\S*)$/\1/p' /etc/os-release)"

	case "${os_id}" in
		debian | ubuntu)
			deb_packages "${mode}"
			;;
		fedora | centos)
			rpm_packages "${mode}"
			;;
		*)
			echo "I can't install packages for your system."
			;;
	esac
}

main "$@"
