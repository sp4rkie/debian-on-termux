#!/data/data/com.termux/files/usr/bin/sh

# oldstable, stable, testing, unstable
BRANCH=testing
# base(258M), minbase(217M), buildd, fakechroot
VAR=minbase
# list_close_debian_mirrors.sh
REPO=http://ftp.debian.org/debian/

set -e
trap '[ $? -eq 0 ] && exit 0 || (echo; echo "termux-info:"; termux-info)' EXIT

if [ ! -d ~/debian-$BRANCH ] ; then
	ARCH=$(uname -m)
	case $ARCH in
		aarch64) ARCH=arm64 ;;
		x86_64) ARCH=amd64 ;;
		i686) ARCH=i386 ;;
		armv7l) ARCH=armhf ;;
		armv8l) apt-get -qq install getconf; if [ $(getconf LONG_BIT) -eq 64 ]; then ARCH=arm64; else ARCH=armhf; fi ;;
		*) echo "Unsupported architecture $ARCH"; exit ;;
	esac
	apt-get -qq update
	apt-get -qq dist-upgrade
	apt-get -qq install debootstrap proot wget
	debootstrap \
		--variant=$VAR \
		--exclude=systemd \
		--arch=$ARCH \
		$BRANCH \
		~/debian-$BRANCH \
		$REPO
fi
unset LD_PRELOAD
proot \
	-0 \
	--link2symlink \
	-r ~/debian-$BRANCH \
	-w /root \
	-b /dev/ \
	-b /sys/ \
	-b /proc/ \
	-b /data/data/com.termux/files/home \
	/usr/bin/env -i \
	HOME=/root \
	TERM="xterm-256color" \
	PATH=/bin:/usr/bin:/sbin:/usr/sbin \
	/bin/bash --login
