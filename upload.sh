sh feeds/x/rom/lede/gen_map.sh

for i in `cat map.list | cut -d: -f2`; do
	find bin/targets -type f -name $i
done | tee upload.list

mkdir -p rom/sdk
mv `cat upload.list` map.list sha256sums.txt rom
test -f sdk_upload.list || exit 0
mv `cat sdk_upload.list` sdk_map.list sdk_sha256sums.txt rom/sdk
