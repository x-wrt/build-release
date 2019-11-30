
change=
NEEDS=
ASSET_NAMES=

for target in `cat target.list`; do
	test -n "$1" && {
		echo $target | grep -q "$1" || continue
	}
	TAG="`cat release.tag`"
	TARGET="`echo -n $target | sed 's/TARGET=//'`"
	ASSET_NAME="x-wrt-${TAG}-${TARGET}"
	echo push ${ASSET_NAME}

	test -n "$change" || {
		cat release-header.yml | sed "s/_TAG_/${TAG}/g" >.github/workflows/release.yml
		change=1
	}
	cat release-main.yml | sed "s/_TARGET_/${TARGET}/g;s/_ASSET_NAME_/${ASSET_NAME}/g" >>.github/workflows/release.yml
	NEEDS="$NEEDS build-${TARGET}"
	ASSET_NAMES="${ASSET_NAMES} ${ASSET_NAME}"
done

test -n "$change" || exit 0

NEEDS=`echo -n $NEEDS | sed 's/ /,/g'`
cat release-post.yml | sed "s/_NEEDS_/[${NEEDS}]/g" >>.github/workflows/release.yml

for ASSET_NAME in ${ASSET_NAMES}; do
	ASSET_ID=`echo ${ASSET_NAME} | tr \. -`
	cat release-end.yml | sed "s/_ASSET_NAME_/${ASSET_NAME}/g;s/_ASSET_ID_/${ASSET_ID}/g" >>.github/workflows/release.yml
done

TAG="v`cat release.tag`"
git commit --signoff -am "release: $TAG" && \
		git tag $TAG && \
		git push origin parallel-jobs
