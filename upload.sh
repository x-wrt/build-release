. .build_x/env

for cfg in $CFGS; do

export CFGS="$cfg"
sh feeds/x/rom/lede/gen_map.sh

echo gen zip
mkdir -p rom/sdk
cp `find $(cat upload.list | cut -d/ -f1,2,3,4 | sort | uniq) | grep kmod-mtd-rw` rom
mv `cat upload.list` map.list sha256sums.txt rom
mv `cat sdk_upload.list` sdk_map.list sdk_sha256sums.txt rom/sdk
sh -c "cd rom && sh ../gen_index.sh"
sh -c "cd rom/sdk && sh ../../gen_sdk_index.sh"

#cleanup space
rm -rf build_dir/t* staging_dir/t*

echo gen x-wrt-${CONFIG_VERSION_NUMBER}-${cfg##config.}.zip
zip -r x-wrt-${CONFIG_VERSION_NUMBER}-${cfg##config.}.zip rom && rm -rf rom || exit 255

done
