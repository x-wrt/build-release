
BTARGET=${BTARGET-x86_64}

CFGS=`for t in $BTARGET; do
	cat ./feeds/x/rom/lede/cfg.list | grep "^config.$t$"
done`

export CFGS="`echo $CFGS`"
export WORKFLOW="0"

echo starting build.
echo starting build..
echo starting build...
echo starting build....
df -h .
free -m
echo start build in 10s
sleep 10

mkdir .build_x
echo CONFIG_VERSION_NUMBER=\"`cat release.tag`\" >.build_x/env
sed -i 's/CONFIG_SDK/# CONFIG_SDK is not set/' ./feeds/x/rom/lede/config.*

TMPFS=1 ./feeds/x/rom/lede/make.sh make -j$1 && sh upload.sh

_EXIT=$?
[ "x$_EXIT" = "x0" ] || {
	sudo -E df -h
	sudo -E du -sh /data_dir/* /mnt/work_dir/
	make V=s >>make.log 2>&1
	exit $_EXIT
}
