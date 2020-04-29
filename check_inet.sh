#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

#
# check internet connection
#

curl networkcheck.kde.org 2> /dev/null | grep -E -c '^OK$' | grep -E '^1$' > /dev/null
