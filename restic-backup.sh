#!/usr/bin/env bash
set -euo pipefail
shopt -s extglob nullglob
IFS=$'\n\t'

restart() {
  systemctl restart gitea
}

trap restart INT QUIT TERM ERR

if [[ -n $(pgrep 'restic' | grep 'restic backup') ]]; then
  echo 'restic is already running...' 1>&2
  exit 0
fi

export AWS_PROFILE=deponian
export AWS_SHARED_CREDENTIALS_FILE=/home/rufus/.aws/credentials
export RESTIC_PASSWORD_FILE=/home/rufus/.restic/deponian.password
export RESTIC_REPOSITORY=s3:s3.amazonaws.com/xxxxxxxx/xxxxxxxxxxxxxxxxxxxxx
export RESTIC_COMPRESSION=max
export RESTIC_KEY_HINT=xxxxxxxx

# /etc
cd /etc
restic backup --no-scan --tag etc . --skip-if-unchanged
restic forget --tag etc --keep-last 1000

# Gitea
systemctl stop gitea
cd /var/lib/gitea
restic backup --no-scan --host common --tag gitea . --skip-if-unchanged
systemctl start gitea
restic forget --tag gitea --keep-last 1000

# Prune
restic prune
