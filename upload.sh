#!/bin/sh
set -eu
set -f

sh feeds/x/rom/lede/gen_map.sh

: >upload.list
while IFS=: read -r device images || [ -n "$device$images" ]; do
	for image in $images; do
		[ "$image" = sha256sums.txt ] && continue
		paths=$(find bin/targets -type f -name "$image")
		[ -n "$paths" ] && [ "$(printf '%s\n' "$paths" | wc -l)" -eq 1 ] || {
			echo "Expected exactly one artifact for: $image" >&2
			exit 1
		}
		printf '%s\n' "$paths" >>upload.list
	done
done <map.list
sort -u upload.list -o upload.list
[ -s upload.list ] || {
	echo "No firmware artifacts found" >&2
	exit 1
}

# Check all inputs before moving any build artifacts.
for metadata in sha256sums.txt sdk_map.list sdk_sha256sums.txt sdk_upload.list; do
	[ -f "$metadata" ] || { echo "Missing $metadata" >&2; exit 1; }
done
while IFS= read -r file || [ -n "$file" ]; do
	[ -n "$file" ] || continue
	[ -f "$file" ] || { echo "Missing SDK artifact: $file" >&2; exit 1; }
done <sdk_upload.list

mkdir -p rom/sdk
target_dirs=$(cut -d/ -f1-4 upload.list | sort -u)
for target_dir in $target_dirs; do
	packages=$(find "$target_dir" -type f -name 'kmod-mtd-rw*')
	for package in $packages; do
		cp -- "$package" rom/
	done
done
while IFS= read -r file || [ -n "$file" ]; do
	mv -- "$file" rom/
done <upload.list
mv map.list sha256sums.txt rom/
while IFS= read -r file || [ -n "$file" ]; do
	[ -n "$file" ] || continue
	mv -- "$file" rom/sdk/
done <sdk_upload.list
mv sdk_map.list sdk_sha256sums.txt rom/sdk/
(cd rom && sh ../gen_index.sh)
(cd rom/sdk && sh ../../gen_sdk_index.sh)
