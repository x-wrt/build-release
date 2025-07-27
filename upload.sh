. .build_x/env

sh feeds/x/rom/lede/gen_map.sh
rm -rf build_dir/t* staging_dir/t*

for cfg in $CFGS; do

mkdir rom
cp `find bin | grep kmod-mtd-rw` rom || true
cp `find bin | grep luci-theme-argon` rom || true
cp `find bin | grep openlist` rom || true
echo gen x-wrt-${CONFIG_VERSION_NUMBER}-${cfg##config.}-apps.zip
zip -r x-wrt-${CONFIG_VERSION_NUMBER}-${cfg##config.}-apps.zip rom && rm -rf rom || exit 255

echo gen zip
cat .build_x/$cfg | grep "^CONFIG_TARGET_DEVICE_[^P]*_DEVICE_.*=y" | awk '{print length(), $0 | "sort -n -r"}' | cut -d' ' -f2 | sed 's/_DEVICE_/ /g;s/=y//' | while read _ target device; do
	mkdir -p rom
	target="$(echo $target | tr _ -)"
	echo target=$target device=$device
	cat map.list | grep "${target}-${device}-" >rom/map.list
	cat upload.list | grep "${target}-${device}-" >rom/upload.list
	cat sha256sums.txt | grep "${target}-${device}-" >rom/sha256sums.txt
	mv `cat rom/upload.list` rom
	sh -c "cd rom && sh ../gen_index.sh"
	echo gen x-wrt-${CONFIG_VERSION_NUMBER}-${cfg##config.}-${device}.zip
	zip -r x-wrt-${CONFIG_VERSION_NUMBER}-${cfg##config.}-${device}.zip rom && rm -rf rom || exit 255
done

done
