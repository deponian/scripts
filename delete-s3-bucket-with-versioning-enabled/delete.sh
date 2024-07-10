#!/usr/bin/env bash
set -euo pipefail
shopt -s extglob nullglob
IFS=$'\n\t'

while true
do
	date
	aws s3api list-object-versions --bucket "bucket-name" --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --max-items 100000 > all.json
	#aws s3api list-object-versions --bucket "bucket-name" --query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --max-items 100000 > all.json
	./json-array-splitter.py
	for part in ./parts/*; do
		aws s3api delete-objects --bucket "bucket-name" --no-cli-pager --delete "$(cat "${part}")"
	done
	rm all.json
	rm -rf parts/
done
