#!/bin/sh
set -eu

[ "$#" -eq 1 ] && [ -n "$1" ] || {
	echo "sh $0 <target>"
	exit 1
}

target="TARGET=$1"
grep -Fxq -- "$target" target.list || {
	echo "Unknown target: $1 (see target.list)" >&2
	exit 1
}
release=$(cat release.tag)
case "$release" in
	''|*[!A-Za-z0-9._-]*) echo "Invalid release tag: $release" >&2; exit 1 ;;
esac
branch=$(git symbolic-ref --short HEAD) && [ "$branch" = master ] || {
	echo "Run this script from the master branch" >&2
	exit 1
}
TAG="$release=$1"
workflow=.github/workflows/main.yml
tmp=$(mktemp "$workflow.XXXXXX")
trap 'rm -f "$tmp"' EXIT
trap 'exit 1' HUP INT TERM

sed -e "s/name: x-wrt-.*=.*/name: x-wrt-$TAG/g" \
	-e "s/TARGET=.* sh /$target sh /" "$workflow" >"$tmp"
cat "$tmp" >"$workflow"

echo "push $TAG"
# Commit only the release inputs, preserving unrelated work and staged files.
git commit --only --allow-empty --signoff -m "release: $TAG" -- "$workflow" release.tag
git push origin master
