
TARGET=ramips

CFGS=`cat ./feeds/x/rom/lede/cfg.list | grep $TARGET`

export CFGS="`echo $CFGS`"
export TMPFS="1"

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
