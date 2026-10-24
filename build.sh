#!/bin/sh
set -eu

TARGET=${TARGET-x86_64}
jobs=${1:-$(nproc)}
case "$jobs" in
	''|*[!0-9]*) echo "Invalid job count: $jobs" >&2; exit 1 ;;
esac
[ "$#" -le 1 ] && [ "$jobs" -gt 0 ] || {
	echo "Usage: sh $0 [positive job count]" >&2
	exit 1
}

CFGS=$(grep -Fx -- "config.$TARGET" ./feeds/x/rom/lede/cfg.list) || {
	echo "No build configuration for target: $TARGET" >&2
	exit 1
}
[ -f "./feeds/x/rom/lede/$CFGS" ] || {
	echo "Missing build configuration: $CFGS" >&2
	exit 1
}

export CFGS
export WORKFLOW="1"

release=$(cat release.tag)
case "$release" in
	''|*[!A-Za-z0-9._-]*) echo "Invalid release tag: $release" >&2; exit 1 ;;
esac

echo "Starting build for $TARGET with $jobs jobs."
df -h .
free -m

mkdir -p .build_x
printf 'CONFIG_VERSION_NUMBER="%s"\n' "$release" >.build_x/env
if ./feeds/x/rom/lede/make.sh make "-j$jobs"; then
	sh upload.sh
else
	status=$?
	make V=s >>../make.log 2>&1 || :
	exit "$status"
fi
