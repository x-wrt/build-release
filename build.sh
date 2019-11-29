
#export CFGS=config.ipq40xx-generic

mkdir .build_x
echo CONFIG_VERSION_NUMBER=\"`cat release.tag`\" >.build_x/env
./feeds/x/rom/lede/make.sh make -j$1 && sh upload.sh
