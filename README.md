# How to build x-wrt for your devices


## First, fork this repository to your github account.

## Clone it from your fork.

```
git clone https://github.com/[your_account]/build-release.git
```

## Select a release tag to build.

You can find available tags at [https://github.com/x-wrt/x-wrt/releases](https://github.com/x-wrt/x-wrt/releases)

For example tag `6.0_b201911290805`
```
echo -n 6.0_b201911290805 >release.tag
```
Then you are going to build release tag `6.0_b201911290805`

If you want to build master branch, then use `master` as tag name
```
echo -n master >release.tag
```

## Run `sh update-tags.sh <target>` to start building your target.

Available targets see `cat target.list`
```
TARGET=ar71xx
TARGET=ath79
TARGET=ramips-mt7620
TARGET=ramips-mt7621
TARGET=ramips-mt76x8
TARGET=ramips-rt3883
TARGET=ramips-rt305x
TARGET=ipq40xx-generic
TARGET=sunxi-cortexa7
TARGET=brcm2708-bcm2709
TARGET=ipq806x-generic
TARGET=kirkwood-generic
TARGET=mvebu-cortexa9
TARGET=bcm53xx-generic
TARGET=brcm2708-bcm2710
TARGET=brcm2708-bcm2711
TARGET=x86_64
TARGET=x86_generic
```

For example, to build all `ipq40xx-generic` target devices, please run:
```
sh update-tags.sh ipq40xx-generic
```

## What target is your device?

You can find your device firmware at [https://downloads.x-wrt.com/rom/](https://downloads.x-wrt.com/rom/)

and then you should known the target name

for example:

`Xiaomi Mi Router R3` target is `ramips-mt7620`

`P&W R619AC` target is `ipq40xx-generic`

`x86 64bits` target is `x86_64`

...
