
TARGET=${TARGET-x86_64}

CFGS=`cat ./feeds/x/rom/lede/cfg.list | grep "config.$TARGET$"`

export CFGS="`echo $CFGS`"
export WORKFLOW="1"

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
./feeds/x/rom/lede/make.sh make -j$1 && sh upload.sh

_EXIT=$?
[ "x$_EXIT" = "x0" ] || {
	make V=s >>../make.log 2>&1
	exit $_EXIT
}
