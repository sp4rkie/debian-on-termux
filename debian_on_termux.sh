#!/data/data/com.termux/files/usr/bin/sh

#
# some configuration. adapt this to your needs
#
DO_FIRST_STAGE=: # false   # required (unpack phase/ executes outside guest invironment)
DO_SECOND_STAGE=: # false  # required (complete the install/ executes inside guest invironment)
DO_THIRD_STAGE=: # false   # optional (enable local policies/ executes inside guest invironment)
VERSION=stable             # supported debian versions include: stretch, stable, testing, unstable
ROOTFS_TOP=deboot_debian   # name of the top install directory

#
# some automatic configuration.
#
set -e
ZONEINFO=$(getprop persist.sys.timezone)     # set your desired time zone
ARCHITECTURE=$(uname -m)
case $ARCHITECTURE in    # supported architectures include: armel, armhf, arm64, i386, amd64
	aarch64) ARCHITECTURE=arm64 ;;
	x86_64) ARCHITECTURE=amd64 ;;
	armv7l) ARCHITECTURE=armhf ;;
	armv8l) ARCHITECTURE=armhf ;;
	armel|armhf|arm64|i386|amd64|mips|mips64el|mipsel|ppc64el|s390x) ;; # Officially supported Debian Stretch architectures
	*) echo "Unsupported architecture $ARCHITECTURE"; exit ;;
esac

filter() {
    grep -Ev '^$|^WARNING: apt does'
}

fallback() {
	echo "patching $V failed using fallback"
	cd ..
	rm -rf debootstrap
	V=debootstrap-1.0.95
	wget https://github.com/sp4rkie/debian-on-termux/files/1991333/$V.tgz.zip -O - | tar xfz -
	V=$(echo "$V" | sed 's/_/-/g')
	ln -nfs $V debootstrap
	cd debootstrap
}

USER_ID=$(id -u)
USER_NAME=$(id -un)
unset LD_PRELOAD # just in case termux-exec is installed
#
# workaround https://github.com/termux/termux-app/issues/306
# workaround https://github.com/termux/termux-packages/issues/1644
# or expect 'patch' to fail when doin the install via ssh and sh (not bash) is used
#
export TMPDIR=$PREFIX/tmp
cd
#
# ===============================================================
# first stage - do the initial unpack phase of bootstrapping only
#
$DO_FIRST_STAGE && {
[ -e "$HOME/$ROOTFS_TOP" ] && {
    echo the target install directory already exists, to continue please remove it by
    echo rm -rf "$HOME/$ROOTFS_TOP"
    exit
}
apt update 2>&1 | filter

unset RESOLV
[ -e $PREFIX/etc/resolv.conf ] || {
    RESOLV=resolv-conf
}

DEBIAN_FRONTEND=noninteractive apt -y install coreutils perl proot sed wget $RESOLV 2>&1 | filter
hash -r
rm -rf debootstrap
V=$(wget http://http.debian.net/debian/pool/main/d/debootstrap/ -qO - | sed 's/<[^>]*>//g' | grep -E '\.[0-9]+\.tar\.gz' | tail -n 1 | sed 's/^ +//g;s/.tar.gz.*//g')
wget "http://http.debian.net/debian/pool/main/d/debootstrap/$V.tar.gz" -O - | tar xfz -
V=$(echo $V | sed 's/_/-/g')
ln -nfs "$V" debootstrap
cd debootstrap
#
# minimum patch needed for debootstrap to work in this environment
#
patch << 'EOF' || fallback
--- debootstrap-1.0.108.orig/functions
+++ debootstrap-1.0.108/functions
@@ -1136,6 +1136,10 @@
 }
 
 setup_proc () {
+
+echo setup_proc
+return 0
+
 	case "$HOST_OS" in
 	    *freebsd*)
 		umount_on_exit /dev
@@ -1247,6 +1251,10 @@
 
 
 setup_devices_simple () {
+
+echo setup_devices_simple
+return 0
+
 	# The list of devices that can be created in a container comes from
 	# src/core/cgroup.c in the systemd source tree.
 	mknod_if_needed "$TARGET/dev/null"        c 1 3
EOF
#
# you can watch the debootstrap progress via
# tail -F $HOME/$ROOTFS_TOP/debootstrap/debootstrap.log
#
export DEBOOTSTRAP_DIR=$(pwd)
"$PREFIX/bin/proot" \
    -b /system \
    -b /vendor \
    -b /data \
    -b "$PREFIX/bin:/bin" \
    -b "$PREFIX/etc:/etc" \
    -b "$PREFIX/lib:/lib" \
    -b "$PREFIX/share:/share" \
    -b "$PREFIX/tmp:/tmp" \
    -b "$PREFIX/var:/var" \
    -b /dev \
    -b /proc \
    -r "$PREFIX/.." \
    -0 \
    --link2symlink \
    ./debootstrap --foreign --arch="$ARCHITECTURE" "$VERSION" "$HOME/$ROOTFS_TOP" \
                                                                || : # proot returns invalid exit status
} # end DO_FIRST_STAGE

#
# =================================================
# second stage - complete the bootstrapping process
#
$DO_SECOND_STAGE && {
# since there are issues with proot and /proc mounts (https://github.com/termux/termux-packages/issues/1679)
# we currently cease from mounting /proc.
# the guest system now is setup to complete the installation - just dive in
# UPDATE as of 2017_11_27:
# issue https://github.com/termux/termux-packages/issues/1679#ref-commit-bcc972c now got fixed.
# /proc now included in mount list
"$PREFIX/bin/proot" \
    -b /dev \
    -b /proc \
    -r "$HOME/$ROOTFS_TOP" \
    -w /root \
    -0 \
    --link2symlink \
    /usr/bin/env -i HOME=/root TERM=xterm PATH=/usr/sbin:/usr/bin:/sbin:/bin /debootstrap/debootstrap --second-stage \
                                                                                || : # proot returns invalid exit status

#
# Add termux user in the passwd, group and shadow.
#
echo "$USER_NAME:x:$USER_ID:$USER_ID::/home/$USER_NAME:/bin/bash" >> \
    $HOME/$ROOTFS_TOP/etc/passwd
echo "$USER_NAME:x:$USER_ID:" >> \
    $HOME/$ROOTFS_TOP/etc/group
echo "$USER_NAME:*:15277:0:99999:7:::" >> \
    $HOME/$ROOTFS_TOP/etc/shadow

#
# add the termux user homedir to the new debian guest system
#
mkdir -p "$HOME/$ROOTFS_TOP/home/$USER_NAME"
chmod 755 "$HOME/$ROOTFS_TOP/home/$USER_NAME"
} # end DO_SECOND_STAGE

#
# ======================================================================================
# optional third stage - if enabled edit some system defaults - adapt this to your needs
#
$DO_THIRD_STAGE && {

#
# take over an existing 'resolv.conf' from the host system (if there is one)
#
[ -e "$HOME/$ROOTFS_TOP/etc/resolv.conf" ] || {
    cp "$PREFIX/etc/resolv.conf" "$HOME/$ROOTFS_TOP/etc/resolv.conf"
    chmod 644 "$HOME/$ROOTFS_TOP/etc/resolv.conf"
}

#
# to enter the debian guest system execute '$HOME/bin/enter_deb' on the termux host system
#
mkdir -p "$HOME/bin"
cat << EOF > "$HOME/bin/enter_deb"
#!/data/data/com.termux/files/usr/bin/sh

unset LD_PRELOAD
SHELL_=/bin/bash
ROOTFS_TOP_=$ROOTFS_TOP
ROOT_=1
USER_=$USER_NAME
EOF
cat << 'EOF' >> "$HOME/bin/enter_deb"

SCRIPTNAME=enter_deb
show_usage () {
        echo "Usage: $SCRIPTNAME [options] [command]"
        echo "$SCRIPTNAME: enter the installed debian guest system"
        echo ""
        echo "  -0 - mimic root (default)"
        echo "  -n - prefer regular termux uid ($USER_)"
        exit 0
}

while getopts :h0n option
do
        case "$option" in
                h) show_usage;;
                0) ;;
                n) ROOT_=0;;
                ?) echo "$SCRIPTNAME: illegal option -$OPTARG"; exit 1;
        esac
done
shift $(($OPTIND-1))

HOMEDIR_=/home/$USER_
[ $ROOT_ = 1 ] && {
    CAPS_=$CAPS_"-0 "
    HOMEDIR_=/root
}
CMD_="$SHELL_ -l"
[ -z "$*" ] || {
    CMD_='sh -c "$*"'
}
eval $PREFIX/bin/proot \
    -b /dev \
    -b /proc \
    -r $HOME/$ROOTFS_TOP_ \
    -w $HOMEDIR_ \
    $CAPS_ \
    --link2symlink \
    /usr/bin/env -i HOME=$HOMEDIR_ TERM=$TERM LANG=$LANG $CMD_
EOF
chmod 755 "$HOME/bin/enter_deb"

cat << 'EOF' > "$HOME/$ROOTFS_TOP/root/.profile"
# ~/.profile: executed by Bourne-compatible login shells.

if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi
EOF

cat << EOF > "$HOME/$ROOTFS_TOP/tmp/dot_tmp.sh"
#!/bin/sh

filter() {
    egrep -v '^$|^WARNING: apt does'
}

#
# select 'vi' as default editor for debconf/frontend
#
update-alternatives --config editor << !
2
!
#
# prefer a text editor for debconf (a GUI makes no sense here)
#
cat << ! | debconf-set-selections -v
debconf debconf/frontend                       select Editor
debconf debconf/priority                       select low
locales locales/locales_to_be_generated        select en_US.UTF-8 UTF-8
locales locales/default_environment_locale     select en_US.UTF-8
!
ln -nfs /usr/share/zoneinfo/$ZONEINFO /etc/localtime
dpkg-reconfigure -fnoninteractive tzdata
dpkg-reconfigure -fnoninteractive debconf

DEBIAN_FRONTEND=noninteractive apt -y update 2>&1 | filter                    
DEBIAN_FRONTEND=noninteractive apt -y upgrade 2>&1 | filter
DEBIAN_FRONTEND=noninteractive apt -y install locales 2>&1 | filter
update-locale LANG=en_US.UTF-8 LC_COLLATE=C
#
# place any additional packages here as you like
#
#DEBIAN_FRONTEND=noninteractive apt -y install rsync less gawk ssh 2>&1 | filter  
apt clean 2>&1 | filter
EOF
chmod 755 "$HOME/$ROOTFS_TOP/tmp/dot_tmp.sh"

"$PREFIX/bin/proot" \
    -b /dev \
    -b /proc \
    -r "$HOME/$ROOTFS_TOP" \
    -w /root \
    -0 \
    --link2symlink \
    /usr/bin/env -i HOME=/root TERM=xterm PATH=/usr/sbin:/usr/bin:/sbin:/bin /tmp/dot_tmp.sh \
                                                      || : # proot returns invalid exit status
echo 
echo installation successfully completed
echo to enter the guest system type:
echo "\$HOME/bin/enter_deb"
echo

} # end DO_THIRD_STAGE
