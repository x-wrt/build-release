
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

sudo -E mkdir /data_dir && sudo -E chmod 777 /data_dir
rm -rf staging_dir
mkdir -p /data_dir/staging_dir && ln -s /data_dir/staging_dir staging_dir
mkdir -p /data_dir/bin && ln -s /data_dir/bin bin
mkdir -p /data_dir/dl && ln -s /data_dir/dl dl
mkdir -p /data_dir/host && mkdir -p build_dir && ln -s /data_dir/host build_dir/host
mkdir -p /data_dir/hostpkg && mkdir -p build_dir && ln -s /data_dir/hostpkg build_dir/hostpkg
#mkdir -p /data_dir/build_dir_host
#mkdir -p build_dir/target-aarch64_cortex-a53_musl && ln -s /data/build_dir_host build_dir/target-aarch64_cortex-a53_musl/host
mkdir -p /data_dir/build_dir_tmp
mkdir -p build_dir/target-aarch64_cortex-a53_musl/linux-mediatek_filogic && ln -s /data_dir/build_dir_tmp build_dir/target-aarch64_cortex-a53_musl/linux-mediatek_filogic/tmp
mkdir -p build_dir/target-x86_64_musl && ln -s /data/build_dir_host build_dir/target-x86_64_musl/host

TMPFS=1 ./feeds/x/rom/lede/make.sh make -j$1 && sh upload.sh

_EXIT=$?
[ "x$_EXIT" = "x0" ] || {
	sudo -E du -sh /data_dir/*
	sudo -E df -h
	sudo -E du -sh bin build_dir/* staging_dir/*
	make V=s >>make.log 2>&1
	exit $_EXIT
}
