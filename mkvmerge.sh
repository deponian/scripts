#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

for file in *.mkv; do
	name="${file%.mkv}"
	mkvmerge -o "${file}".new "${file}" \
		--language "0:rus" --track-name "0:Russian" "${name}.audio.rus.mka" \
		--language "0:rus" --track-name "0:Полные (a2react)" "${name}.a2react.rus.ass" \
		--language "0:rus" --track-name "0:Полные (Kiyoso)" "${name}.kiyoso.rus.ass" \
		--language "0:rus" --track-name "0:Надписи" "${name}.signs.rus.ass" \
		--attachment-mime-type "application/x-truetype-font" \
		--attach-file "Antikvarika.ttf" \
		--attachment-mime-type "application/x-truetype-font" \
		--attach-file "CHICAGO.TTF" \
		--attachment-mime-type "application/x-truetype-font" \
		--attach-file "Hortensia.ttf" \
		--attachment-mime-type "application/x-truetype-font" \
		--attach-file "IRINA.TTF" \
		--attachment-mime-type "application/x-truetype-font" \
		--attach-file "NEWYORK.TTF"
done

