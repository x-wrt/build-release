
cat target.list | while read target; do
	test -n "$1" && {
		echo $target | grep -q "$1" || continue
	}
	TAG="`cat release.tag`-$target"
	echo push $TAG
	sleep 2

	sed -i "s/name: build-x-wrt-.*/name: build-x-wrt-$TAG/g" .github/workflows/main.yml && \
		sed -i "s/^TARGET=.*/$target/" build.sh && \
		git commit --signoff -am "release: $TAG" && \
		git push origin master || exit 1
done
