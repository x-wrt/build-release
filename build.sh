
CFGS="
config.ar71xx-generic
config.ar71xx-generic-nosymbol
config.ar71xx-nand
config.ar71xx-nand-nosymbol
config.ar71xx-tiny
config.ath79-generic
config.ath79-generic-nosymbol
config.ath79-nand
config.ramips-mt7620
config.ramips-mt7620-nosymbol
config.ramips-mt7621
config.ramips-mt76x8
config.ramips-mt76x8-nosymbol
config.ramips-rt3883-nosymbol
config.ramips-rt305x
config.ipq40xx-generic
config.ipq806x-generic
"

export CFGS="`echo $CFGS`"

mkdir .build_x
echo CONFIG_VERSION_NUMBER=\"`cat release.tag`\" >.build_x/env
./feeds/x/rom/lede/make.sh make -j$1 && sh upload.sh
