
CFGS="
config.ath79-generic
config.ath79-generic-nosymbol
config.ath79-nand
config.ramips-mt7620
config.ramips-mt7620-nosymbol
config.ramips-mt7621
config.ramips-mt76x8
config.ramips-mt76x8-nosymbol
config.ipq40xx-generic
"

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
