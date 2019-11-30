
cat target.list | while read target; do
	test -n "$1" && {
		echo $target | grep -q "$1" || continue
	}
	TAG="`cat release.tag`""`echo -n $target | sed 's/TARGET//'`"
	TAGNAME="`echo -n $TAG | sed 's/=/-/g'`"
	echo push $TAG

	sed -i "s/name: x-wrt-.*=.*/name: x-wrt-$TAG/" main.yml && \
		sed -i "s/asset_name: x-wrt-.*-.*\.zip/asset_name: x-wrt-$TAGNAME\.zip/" main.yml && \
		sed -i "s/TARGET=.* sh /$target sh /" main.yml && \
		cp main.yml .github/workflows/$target.yml
done

TAG="v`cat release.tag`"
git commit --signoff -am "release: $TAG" && \
		git tag $TAG && \
		git push origin parallel-jobs
