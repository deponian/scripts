#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

#
# download necessary static linked utils from various places
#

# all downloaded binaries will be placed in this directory before moving to ${install_path} (see main() below)
tmp_path="/tmp/${RANDOM}"

check_software () {
	for program in "$@"
	do
		command -v ${program} >/dev/null 2>&1 || \
		{
			echo >&2 -e "Aborting.\nThis script needs these programs: \n${*}"
			exit 1
		}
	done
}

check_if_it_is_arch_linux () {
	local os_id="$(sed -n -E -e 's/^ID=(\S*)$/\1/p' /etc/os-release)"
	if [[ "${os_id}" == "arch" ]]; then
		pacman --noconfirm -S fd bat fzf ripgrep git-delta hexyl
		exit 0
	fi
}

# downloads one asset and save it as "project.asset"
# usage: download_github_asset user/project filter1 [fileter2 [filter3...]]
download_github_asset () {
	# returns 0 if str contains ALL substrs
	# returns 1 if str doesn't contain at least one substr
	# usage: substrs_in_str str substr1 [substr2 [substr3...]]
	substrs_in_str () {
		local str substrs

		str="${1:?"You have to specify string as first parametr"}"
		shift
		substrs=("$@")
		if [[ "${#substrs[@]}" == 0 ]]; then
			echo "You have to specify at least one substring after string" >&2
			exit 1
		fi

		for substr in "${substrs[@]}"; do
			str="$(grep "${substr}" <<< "${str}")"
		done
		if [[ -n "${str}" ]]; then
			echo 0
		else
			echo 1
		fi
	}

	local user_project user project filters assets

	user_project="${1:?"You have to set first parametr as user/project"}"
	shift
	filters=("$@")

	if [[ "${#filters[@]}" == 0 ]]; then
		echo "You have to set at least one filter as second parametr" >&2
		exit 1
	fi

	user="${user_project%/*}"
	project="${user_project#*/}"
	readarray -t assets < <(wget -qO- "https://api.github.com/repos/${user}/${project}/releases/latest" | jq -r ".assets[].name")
	filtered_assets=()

	for asset in "${assets[@]}"; do
		if [[ "$(substrs_in_str "${asset}" "${filters[@]}")" == 0 ]]; then
			filtered_assets+=("${asset}")
		fi
	done

	if [[ "${#filtered_assets[@]}" == 0 ]]; then
		echo "There are no assets matching the specified filters." >&2
		exit 1
	fi

	if [[ ${#filtered_assets[@]} != 1 ]]
	then
		echo "There is more then one asset matching the specified filters." >&2
		echo "List of assets is: ${filtered_assets[*]}" >&2
		exit 1
	else
		# After filtering $filtered_assets shoud contain only one asset
		asset="${filtered_assets[0]}"
	fi

	echo "Download ${user_project}:"
	wget --retry-connrefused \
		--waitretry=1 \
		--quiet \
		--show-progress \
		"https://github.com/${user}/${project}/releases/latest/download/${asset}"

	mv "${asset}" "${project}.asset"
}

# setup sharkdp's (https://github.com/sharkdp) tools
setup_sharkdp () {
	local project

	project="${1:?"You have to specify project as first argument"}"
	mkdir tmp
	cd tmp
	tar -xzf "../${project}.asset"
	mv "$(find . -name "${project}")" ../
	cd ..
	rm -rf tmp
	rm "${project}.asset"
}

setup_fzf () {
	# get fzf binary
	tar -xzf fzf.asset

	# get fzf-tmux script
	wget --retry-connrefused \
		--waitretry=1 \
		--quiet \
		--show-progress \
		"https://raw.githubusercontent.com/junegunn/fzf/master/bin/fzf-tmux"
	chmod +x fzf-tmux

	rm fzf.asset
}

setup_ripgrep () {
	mkdir tmp
	cd tmp
	tar -xzf ../ripgrep.asset
	mv "$(find . -name rg)" ../
	cd ..
	rm -rf tmp
	rm ripgrep.asset
}

setup_delta () {
	mkdir tmp
	cd tmp
	tar -xzf ../delta.asset
	mv "$(find . -name delta)" ../
	cd ..
	rm -rf tmp
	rm delta.asset
}

setup_shellcheck () {
	mkdir tmp
	cd tmp
	tar -xf ../shellcheck.asset
	mv "$(find . -name shellcheck)" ../
	cd ..
	rm -rf tmp
	rm shellcheck.asset
}

main () {
	if [[ "$EUID" != 0 ]]
	then
		echo "Please run as root" >&2
		exit 1
	fi

	# we can use pacman on Arch Linux
	# instead of manual download from Github
	check_if_it_is_arch_linux

	local install_path

	install_path=${1:?"You have to specify install path as first parametr"}

	if [[ ! -d "${install_path}" ]]; then
		echo "${install_path} is not a directory or it doesn't exists" >&2
		exit 1
	fi

	install_path="$(realpath "${install_path}")"

	# all further manipulations (download/untar/unzip etc) will be inside ${tmp_path} dir
	mkdir -p "${tmp_path}"
	(
		cd "${tmp_path}"

		check_software tar unzip wget xz jq

		# :: fd - a modern replacement for unix find
		download_github_asset sharkdp/fd linux x86_64 musl
		setup_sharkdp fd

		# :: bat - a modern replacement for unix cat
		download_github_asset sharkdp/bat linux x86_64 musl
		setup_sharkdp bat

		# :: hexyl - a command-line hex viewer with color support
		download_github_asset sharkdp/hexyl linux x86_64 musl
		setup_sharkdp hexyl

		# :: fzf - a command-line fuzzy finder
		download_github_asset junegunn/fzf linux amd64
		setup_fzf

		# :: ripgrep - a modern replacement for unix grep (or not)
		download_github_asset BurntSushi/ripgrep linux x86_64 musl
		setup_ripgrep

		# :: delta - a viewer for git and diff output
		download_github_asset dandavison/delta linux x86_64 musl
		setup_delta

		# :: shellcheck - a static analysis tool for shell scripts
		download_github_asset koalaman/shellcheck linux x86_64
		setup_shellcheck

		for binary in *; do
			chown "$(id -un):$(id -gn)" "${binary}"
			mv "${binary}" "${install_path}"
		done
	)
	rm -rf "${tmp_path}"
}

main "$@"
