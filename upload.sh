sh feeds/x/rom/lede/gen_map.sh

for i in `cat map.list | cut -d: -f2`; do
	find bin/targets -type f -name $i
done | tee upload.list

mkdir -p rom/sdk
cp `find $(cat upload.list | cut -d/ -f1,2,3,4 | sort | uniq) | grep kmod-mtd-rw` rom
mv `cat upload.list` map.list sha256sums.txt rom
mv `cat sdk_upload.list` sdk_map.list sdk_sha256sums.txt rom/sdk
sh -c "cd rom && sh ../gen_index.sh"
sh -c "cd rom/sdk && sh ../../gen_sdk_index.sh"
