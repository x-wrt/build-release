# How to build x-wrt for your devices


## First, fork this repository to your github account.

## Clone it from your fork.

```
git clone https://github.com/[your_account]/build-release.git
```

## Select a release tag to build.

You can find available tags at [https://github.com/x-wrt/x-wrt/tags](https://github.com/x-wrt/x-wrt/tags)

For example tag `23.06_b202307110013`
```
echo -n 23.06_b202307110013 >release.tag
```
Then you are going to build release tag `23.06_b202307110013`

If you want to build master branch, then use `master` as tag name
```
echo -n master >release.tag
```

## Run `sh update-tags.sh <target>` to start building your target.

Available targets see `cat target.list`
```
TARGET=ath79-generic
TARGET=ath79-generic-nosymbol
TARGET=ath79-nand
TARGET=ipq40xx-generic
TARGET=bcm27xx-bcm2709
TARGET=sunxi-cortexa7
TARGET=bcm27xx-bcm2710
TARGET=mediatek-mt7622
TARGET=mediatek-filogic
TARGET=qualcommax-ipq807x
TARGET=bcm27xx-bcm2711
TARGET=bcm53xx-generic
TARGET=ipq806x-generic
TARGET=kirkwood-generic
TARGET=mvebu-cortexa9
TARGET=ramips-mt7620
TARGET=ramips-mt7620-nosymbol
TARGET=ramips-mt7621
TARGET=ramips-mt7621-ext4fs
TARGET=ramips-mt76x8
TARGET=ramips-mt76x8-nosymbol
TARGET=rockchip-armv8
TARGET=armsr-armv8
TARGET=x86_64
TARGET=x86_64-docker
```

For example, to build all `ipq40xx-generic` target devices, please run:
```
sh update-tags.sh ipq40xx-generic
```

Run this script from the `master` branch. Use the full target name from
`target.list`; partial names and patterns are rejected.
The script commits `.github/workflows/main.yml` and `release.tag`, then pushes
`master` to `origin`. Other modified or staged files are left in place. Running
the same release and target again creates a new build commit.

Release tags may contain letters, digits, dots, underscores, and hyphens.

## Check the release scripts locally

Run the regression tests with Python 3:

```
python3 -m unittest discover -s tests -v
TEST_SHELL='busybox ash' python3 -m unittest discover -s tests -v
```

The tests use temporary directories and local Git repositories. They do not
build firmware or push to GitHub.

## What is your device target?

You can find your device firmware at [https://downloads.x-wrt.com/rom/](https://downloads.x-wrt.com/rom/)

and then you should known the target name

for example:

`Xiaomi Mi Router R3` target is `ramips-mt7620`

`P&W R619AC` target is `ipq40xx-generic`

`x86 64bits` target is `x86_64`

...
