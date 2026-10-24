#!/bin/sh
set -eu
set -f
# shellcheck source=release-common.sh
. "$(dirname "$0")/release-common.sh"

BTARGET=${BTARGET-x86_64}
jobs=${1:-$(nproc)}
case "$jobs" in ''|*[!0-9]*) echo "Invalid job count: $jobs" >&2; exit 1 ;; esac
[ "$#" -le 1 ] && [ "$jobs" -gt 0 ] || {
	echo "Usage: sh $0 [positive job count]" >&2
	exit 1
}
[ -n "$BTARGET" ] || { echo "Empty BTARGET" >&2; exit 1; }
CFGS=
for target in $BTARGET; do
	release_check_name target "$target"
	cfg="config.$target"
	grep -Fxq -- "$cfg" feeds/x/rom/lede/cfg.list && [ -f "feeds/x/rom/lede/$cfg" ] || {
		echo "No build configuration for target: $target" >&2
		exit 1
	}
	case " $CFGS " in *" $cfg "*) ;; *) CFGS="${CFGS:+$CFGS }$cfg" ;; esac
done
export CFGS
export WORKFLOW=0
release=$(cat release.tag)
release_check_name "release tag" "$release"

echo "Starting build for $BTARGET with $jobs jobs."
df -h .
free -m
test -f pigz.tar.gz || wget -O pigz.tar.gz https://www.zlib.net/pigz/pigz.tar.gz
tar xzf pigz.tar.gz
(cd pigz && make && sudo -E cp pigz /bin/pigz && sudo -E ln -sf pigz /bin/unpigz)
git config user.email "dev@x-wrt.com"
git config user.name "Developer X"

mkdir -p .build_x
printf 'CONFIG_VERSION_NUMBER="%s"\n' "$release" >.build_x/env
for cfg in $CFGS; do
	sed -i 's/^CONFIG_SDK=y$/# CONFIG_SDK is not set/' "feeds/x/rom/lede/$cfg"
done

if TMPFS=1 ./feeds/x/rom/lede/make.sh make "-j$jobs"; then
	sh upload.sh
else
	status=$?
	make V=s >>make.log 2>&1 || :
	exit "$status"
fi
