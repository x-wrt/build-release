
cat target.list | while read target; do
	test -n "$1" && {
		echo $target | grep -q "$1" || continue
	}
	TAG="`cat release.tag`""`echo -n $target | sed 's/TARGET//'`"
	echo push $TAG

	sed -i "s/name: x-wrt-.*=.*/name: x-wrt-$TAG/g" main.yml && \
		sed -i "s/TARGET=.* sh /$target sh /" main.yml && \
		cp main.yml .github/workflows/$target.yml
done
