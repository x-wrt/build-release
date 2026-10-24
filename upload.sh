#!/bin/sh
set -eu
set -f
# shellcheck source=release-common.sh
. "$(dirname "$0")/release-common.sh"

: "${CFGS:?Set CFGS to the configurations built by make.sh}"
# shellcheck disable=SC1091
. .build_x/env
sh feeds/x/rom/lede/gen_map.sh
for manifest in map.list upload.list sha256sums.txt; do
	[ -s "$manifest" ] || { echo "Missing or empty $manifest" >&2; exit 1; }
done
# Free the completed build cache before creating release archives.
(set +f; rm -rf build_dir/t* staging_dir/t*)

root=$PWD
work=$(mktemp -d "$root/.release-pack.XXXXXX")
trap 'rm -rf "$work"' EXIT
trap 'exit 1' HUP INT TERM
sort -u sha256sums.txt >"$work/checksums"
: >"$work/claimed"

archive() {
	(cd "$work" && zip -qr archive.zip rom)
	mv -- "$work/archive.zip" "$root/$1.zip"
	rm -rf "$work/rom"
}

for cfg in $CFGS; do
	release_check_name configuration "$cfg"
	config=".build_x/$cfg"
	board=$(release_config_value "$config" CONFIG_TARGET_BOARD)
	subtarget=$(release_config_value "$config" CONFIG_TARGET_SUBTARGET)
	arch=$(release_config_value "$config" CONFIG_TARGET_ARCH_PACKAGES)
	for value in "$board" "$subtarget" "$arch"; do release_check_name architecture "$value"; done
	target_dir="bin/targets/$board/$subtarget"
	[ -d "$target_dir" ] || { echo "Missing $target_dir" >&2; exit 1; }
	devices=$(release_devices "$config")
	[ -n "$devices" ] || { echo "No devices in $cfg" >&2; exit 1; }
	# Assign overlapping device names to the longest matching name first.
	printf '%s\n' "$devices" | awk '{ print length($2), $0 }' | sort -k1,1nr | cut -d' ' -f2- >"$work/devices"
	mkdir "$work/rom"
	for package_dir in "$target_dir/packages" "bin/packages/$arch"; do
		[ -d "$package_dir" ] || continue
		find "$package_dir" -type f \( -name 'kmod-mtd-rw*' -o -name '*luci-theme-argon*' \
			-o -name '*openlist*' -o -name '*zerotier*' -o -name '*tailscale*' -o -name '*openclash*' \) >"$work/packages"
		while IFS= read -r package || [ -n "$package" ]; do
			dest="$work/rom/${package##*/}"
			if [ -e "$dest" ]; then
				cmp -s "$package" "$dest" || { echo "Conflicting package: $package" >&2; exit 1; }
			else
				cp -- "$package" "$dest"
			fi
		done <"$work/packages"
	done
	archive "x-wrt-${cfg#config.}-apps"
	while read -r target device; do
		release_check_name "device target" "$target"
		release_check_name device "$device"
		target=$(printf '%s' "$target" | tr _ -)
		mkdir "$work/rom"
		: >"$work/names"
		while IFS= read -r file || [ -n "$file" ]; do
			case "$file" in "$target_dir/"*) ;; *) continue ;; esac
			name=${file##*/}
			case "$name" in *"$target-$device-"*) ;; *) continue ;; esac
			grep -Fxq -- "$file" "$work/claimed" && continue
			[ -f "$file" ] || { echo "Missing artifact: $file" >&2; exit 1; }
			[ ! -e "$work/rom/$name" ] || { echo "Duplicate artifact: $name" >&2; exit 1; }
			cp -- "$file" "$work/rom/"
			printf '%s\n' "$name" >>"$work/names"
			printf '%s\n' "$file" >>"$work/claimed"
		done <upload.list
		[ -s "$work/names" ] || { echo "No firmware for $cfg / $device" >&2; exit 1; }
		printf 'sha256sums: sha256sums.txt\n' >"$work/rom/map.list"
		: >"$work/indexed"
		while IFS=: read -r name images || [ -n "$name$images" ]; do
			selected=
			for image in $images; do
				if grep -Fxq -- "$image" "$work/names"; then
					selected="${selected:+$selected }$image"
					printf '%s\n' "$image" >>"$work/indexed"
				fi
			done
			[ -z "$selected" ] || printf '%s: %s\n' "$name" "$selected" >>"$work/rom/map.list"
		done <map.list
		sort -u "$work/names" -o "$work/names"
		sort -u "$work/indexed" -o "$work/indexed"
		cmp -s "$work/names" "$work/indexed" || { echo "Firmware missing from map.list" >&2; exit 1; }
		: >"$work/rom/sha256sums.txt"
		while IFS= read -r name; do
			awk -v name="$name" '$2 == name || $2 == "*" name { print; count++ }
				END { if (count != 1) exit 1 }' "$work/checksums" >>"$work/rom/sha256sums.txt"
		done <"$work/names"
		(cd "$work/rom" && sha256sum -c sha256sums.txt && sh "$root/gen_index.sh")
		archive "x-wrt-${cfg#config.}-$device"
	done <"$work/devices"
done

sort -u upload.list >"$work/expected"
sort -u "$work/claimed" -o "$work/claimed"
cmp -s "$work/expected" "$work/claimed" || { echo "Unpackaged firmware in upload.list" >&2; exit 1; }
