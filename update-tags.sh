#!/bin/sh
set -eu
set -f
# shellcheck source=release-common.sh
. "$(dirname "$0")/release-common.sh"

generate_only=0
if [ "${1-}" = --generate-only ]; then
	generate_only=1
	shift
fi
[ "$#" -le 1 ] || { echo "Usage: sh $0 [--generate-only] [target]" >&2; exit 1; }
filter=${1-}
[ -z "$filter" ] || release_check_name target "$filter"
release=$(cat release.tag)
release_check_name "release tag" "$release"
TAG="v$release"
config_dir=${RELEASE_CONFIG_DIR:-../feeds/x/rom/lede}

if [ "$generate_only" -eq 0 ]; then
	branch=$(git symbolic-ref --short HEAD) && [ "$branch" = parallel-jobs ] || {
		echo "Run this script from the parallel-jobs branch" >&2
		exit 1
	}
	if git show-ref --verify --quiet "refs/tags/$TAG"; then
		echo "Tag $TAG already exists; update release.tag first" >&2
		exit 1
	fi
fi

workflow=.github/workflows/release.yml
tmp=$(mktemp "$workflow.XXXXXX")
trap 'rm -f "$tmp" "$tmp.devices"' EXIT
trap 'exit 1' HUP INT TERM
sed "s/_TAG_/$release/g" release-header.yml >"$tmp"
matched=0

append_asset() {
	asset_name=$1
	asset_id=$(printf '%s\n' "$asset_name" | md5sum)
	asset_id=${asset_id%% *}
	sed -e "s/_ASSET_NAME_/$asset_name/g" -e "s/_ASSET_ID_/$asset_id/g" \
		release-upload-one.yml >>"$tmp"
}

while IFS= read -r line || [ -n "$line" ]; do
	[ -n "$line" ] || continue
	case "$line" in
		BTARGET=*) targets=${line#BTARGET=} ;;
		*) echo "Invalid target.list entry: $line" >&2; exit 1 ;;
	esac
	[ -n "$targets" ] || { echo "Empty build target" >&2; exit 1; }
	if [ -n "$filter" ]; then
		case " $targets " in *" $filter "*) ;; *) continue ;; esac
	fi
	matched=$((matched+1))
	target_name=$(printf '%s' "$targets" | tr ' ' _)
	sed -e "s/_TARGET_/$targets/g" -e "s/_TARGETNAME_/$target_name/g" \
		release-main.yml >>"$tmp"
	for bt in $targets; do
		release_check_name target "$bt"
		devices=$(release_devices "$config_dir/config.$bt")
		[ -n "$devices" ] || { echo "No devices in config.$bt" >&2; exit 1; }
		append_asset "x-wrt-$bt-apps"
		# A redirected loop keeps failures in this shell.
		printf '%s\n' "$devices" >"$tmp.devices"
		while read -r target device; do
			release_check_name "device target" "$target"
			release_check_name device "$device"
			append_asset "x-wrt-$bt-$device"
		done <"$tmp.devices"
		rm -f "$tmp.devices"
	done
done <target.list
[ "$matched" -gt 0 ] || { echo "Unknown target: $filter" >&2; exit 1; }
chmod 644 "$tmp"
mv -- "$tmp" "$workflow"

[ "$generate_only" -eq 0 ] || exit 0
git commit --only --signoff -m "release: $TAG" -- "$workflow" release.tag
git tag "$TAG"
git push --atomic origin HEAD:refs/heads/parallel-jobs "refs/tags/$TAG"
