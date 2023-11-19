#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

INPUT_DIR='in'
OUTPUT_DIR='out'

for song_path in "${INPUT_DIR}"/*.flac; do
	name="$(basename -s .flac "${song_path}")"
	if [[ ! -f "${OUTPUT_DIR}/${name}.opus" ]]; then
		ffmpeg -i "${song_path}" -b:a 128000 "${OUTPUT_DIR}/${name}.opus"
	fi
done
