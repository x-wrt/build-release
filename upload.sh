. .build_x/env

sh feeds/x/rom/lede/gen_map.sh
rm -rf build_dir/t* staging_dir/t*

for cfg in $CFGS; do

echo gen zip
cat .build_x/$cfg | grep "^CONFIG_TARGET_DEVICE_[^P]*_DEVICE_.*=y" | sed 's/_DEVICE_/ /g;s/=y//' | while read _ target device; do
	mkdir -p rom
	target=$(echo $target | tr _ -)"
	echo target=$target device=$device
	cp `find $(cat upload.list | cut -d/ -f1,2,3,4 | sort | uniq) | grep kmod-mtd-rw` rom || true
	cp `find $(cat upload.list | cut -d/ -f1,2 | sort | uniq) | grep luci-theme-argon` rom || true
	cp `find $(cat upload.list | cut -d/ -f1 | sort | uniq) | grep openlist` rom || true
	cat map.list | grep "${target}-${device}-" >rom/map.list
	cat upload.list | grep "${target}-${device}-" >rom/upload.list
	cat sha256sums.txt | grep "${target}-${device}-" >rom/sha256sums.txt
	mv `cat rom/upload.list` rom
	sh -c "cd rom && sh ../gen_index.sh"
	echo gen x-wrt-${CONFIG_VERSION_NUMBER}-${cfg##config.}-${device}.zip
	zip -r x-wrt-${CONFIG_VERSION_NUMBER}-${cfg##config.}-${device}.zip rom && rm -rf rom || exit 255
done

done
