
test -n "$1" || {
	echo "sh $0 <target>"
	exit 1
}

cat target.list | while read target; do
	test -n "$1" && {
		echo $target | grep -q "$1$" || continue
	}
	TAG=$(cat release.tag)$(echo $target | sed 's/TARGET//')
	echo push $TAG
	sleep 2

	(sed -i "s/name: x-wrt-.*=.*/name: x-wrt-$TAG/g" .github/workflows/main.yml 2>/dev/null || \
	 sed -i '' "s/name: x-wrt-.*=.*/name: x-wrt-$TAG/g" .github/workflows/main.yml 2>/dev/null) &&
	(sed -i "s/TARGET=.* sh /$target sh /" .github/workflows/main.yml 2>/dev/null || \
	 sed -i '' "s/TARGET=.* sh /$target sh /" .github/workflows/main.yml 2>/dev/null) &&
	git commit --signoff -am "release: $TAG" &&
	git push origin master ||
	exit 1
done
