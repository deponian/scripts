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
		apt -y install --no-install-recommends bash bat bc ccze dnsutils fd-find fzf git htop \
			iputils-ping ncdu neovim openssh-server ripgrep rsync sudo tmux vim zsh
	elif [[ "${mode}" == "server" ]]; then
		apt -y install --no-install-recommends anacron apg apt-transport-https bash bat bc \
			bridge-utils bwm-ng ca-certificates ccze cron curl debsums dnsutils ethtool fd-find \
			fzf gdisk git gnupg2 htop ifupdown ioping iotop iproute2 iputils-ping jid jq less \
			links lsb-release lshw mc mtr-tiny nano ncdu neovim net-tools netcat-openbsd \
			nethogs netmask nmap openssh-server parted progress ripgrep rsync rsyslog shellcheck \
			strace sudo sysstat tcpdump telnet tmux traceroute unzip vim vlan wget xz-utils zsh zstd
	elif [[ "${mode}" == "desktop" ]]; then
		apt -y install --no-install-recommends anacron apg apt-transport-https bash bat bc \
			bridge-utils bwm-ng ca-certificates ccze cron curl debsums dnsutils ethtool fd-find \
			fzf gdisk git gnupg2 htop ifupdown ioping iotop iproute2 iputils-ping jid jq less links \
			lsb-release lshw mc mtr-tiny nano ncdu neovim net-tools netcat-openbsd nethogs \
			netmask nmap openssh-server parted progress ripgrep rsync rsyslog shellcheck strace sudo \
			sysstat tcpdump telnet tmux traceroute unzip vim vim-gui-common vlan wget xz-utils zsh zstd
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
		dnf -y --setopt=install_weak_deps=False install bash bat bc bind-utils ccze fd-find fzf git \
			git-delta htop iputils mlocate ncdu openssh-server ripgrep rsync sudo tmux vim zsh
	elif [[ "${mode}" == "server" ]]; then
		dnf -y --setopt=install_weak_deps=False install apg bash bat bc bind-utils bwm-ng ca-certificates \
			ccze cronie cronie-anacron curl ethtool fd-find fzf gdisk git git-delta gnupg2 htop ioping iotop \
			iputils jid jq less links lshw mc mlocate mtr nano ncdu net-tools nethogs netmask nmap openssh-server \
			parted progress ripgrep rsync rsyslog shellcheck strace sudo sysstat tcpdump telnet tmux traceroute \
			unzip vim wget xz zsh zstd
	elif [[ "${mode}" == "desktop" ]]; then
		dnf -y --setopt=install_weak_deps=False install apg bash bat bc bind-utils bwm-ng cronie-anacron \
			ca-certificates ccze cronie curl ethtool fd-find fzf gdisk git git-delta gnupg2 htop ioping iotop \
			iputils jid jq less links lshw mc mlocate mtr nano ncdu neovim net-tools nethogs netmask nmap \
			openssh-server parted progress ripgrep rsync rsyslog shellcheck strace sudo sysstat tcpdump telnet \
			tmux traceroute unzip vim wget xz zsh zstd
	else
		echo "Something strange happened." >&2
	fi
}

# dnsutils -> bind
# openssh-server -> openssh
# cronie-anacron -> cronie
# apg -> not in core repository
# gnupg2 -> gnupg
# jid -> not in core repository
# netmask -> not in core repository
# rsyslog -> not in core repository
# telnet -> inetutils
arch_packages () {
	local mode

	mode="${1:?"You have to specify mode as first parametr"}"
	if [[ "${mode}" == "minimal" ]]; then
		pacman --noconfirm --needed -S bash bat bc bind fd fzf git \
			git-delta htop iputils mlocate ncdu neovim openssh ripgrep rsync sudo tmux vim zsh
	elif [[ "${mode}" == "server" ]]; then
		pacman --noconfirm --needed -S bash bat bc bind bwm-ng ca-certificates \
			cronie curl ethtool fd fzf gdisk git git-delta gnupg htop inetutils \
			ioping iotop iputils jq less links lsd lshw mc mlocate mtr nano ncdu neovim \
			net-tools nethogs nmap openssh parted progress ripgrep rsync shellcheck strace \
			sudo sysstat tcpdump tmux traceroute unzip vim wget xz zsh zstd
	elif [[ "${mode}" == "desktop" ]]; then
		pacman --noconfirm --needed -S bash bat bc bind bwm-ng ca-certificates cronie \
			curl ethtool fd fzf gdisk git git-delta gnupg htop inetutils ioping iotop iputils \
			jq less links lsd lshw mc mlocate mtr nano ncdu neovim net-tools nethogs nmap \
			openssh parted progress ripgrep rsync shellcheck strace sudo sysstat tcpdump tmux \
			traceroute unzip vim wget xz zsh zstd
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
			read -r -p 'Choose packages mode from "minimal", "server" and "desktop": ' mode
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
		arch)
			arch_packages "${mode}"
			;;
		*)
			echo "I can't install packages for your system."
			;;
	esac
}

main "$@"
