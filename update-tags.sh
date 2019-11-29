
TAG=`cat release.tag`

sed -i "s/name: build-x-wrt-.*/name: build-x-wrt-$TAG/g" .github/workflows/main.yml && \
	git commit --signoff -am "release: $TAG" && \
	git push origin master || exit 1
