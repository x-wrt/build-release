
change=

for target in `cat target.list`; do
	test -n "$1" && {
		echo $target | grep -q "$1" || continue
	}
	TAG="`cat release.tag`"
	TARGET="`echo -n $target | sed 's/TARGET=//'`"
	ASSET_NAME="x-wrt-${TAG}-${TARGET}"
	ASSET_ID=`echo ${ASSET_NAME} | tr \. -`
	echo push ${ASSET_NAME}

	test -n "$change" || {
		cat release-header.yml | sed "s/_TAG_/${TAG}/g" >.github/workflows/release.yml
		change=1
	}
	cat release-main.yml | sed "s/_TARGET_/${TARGET}/g;s/_ASSET_NAME_/${ASSET_NAME}/g;s/_ASSET_ID_/${ASSET_ID}/g" >>.github/workflows/release.yml
done

test -n "$change" || exit 0

TAG="v`cat release.tag`"
git commit --signoff -am "release: $TAG" && \
		git tag $TAG && \
		git push origin parallel-jobs
