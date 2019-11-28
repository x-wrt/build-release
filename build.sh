
export CFGS=config.ipq40xx-generic

./feeds/x/rom/lede/make.sh make -j$1 && sh upload.sh

