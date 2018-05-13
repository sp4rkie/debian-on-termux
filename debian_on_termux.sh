#!/data/data/com.termux/files/usr/bin/sh

#
# some configuration. adapt this to your needs
#
#set -x  
set -e
DO_FIRST_STAGE=: # false   # required (unpack phase/ executes outside guest invironment)
DO_SECOND_STAGE=: # false  # required (complete the install/ executes inside guest invironment)
DO_THIRD_STAGE=: # false   # optional (enable local policies/ executes inside guest invironment)

ARCHITECTURE=$(uname -m | perl -pe 's/aarch64/arm64/g')
                           # supported architectures include: armel, armhf, arm64, i386, amd64
VERSION=stable             # supported debian versions include: stretch, stable, testing, unstable
ROOTFS_TOP=deboot_debian   # name of the top install directory
ZONEINFO=Europe/Berlin     # set your desired time zone

filter() {
    grep -Ev '^$|^WARNING: apt does'
}

fallback() {
	echo "patching $V failed using fallback"
	cd ..
	rm -rf debootstrap
	V=debootstrap-1.0.95
	wget https://github.com/sp4rkie/debian-on-termux/files/1991333/$V.tgz.zip -O - | tar xfz -
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
DEBIAN_FRONTEND=noninteractive apt -y install perl proot 2>&1 | filter                              
rm -rf debootstrap
V=$(wget http://http.debian.net/debian/pool/main/d/debootstrap/ -qO - | perl -pe 's/<.*?>/ /g' | grep -E '\.[0-9]+\.tar\.gz' | tail -n 1 | perl -pe 's/^ +//g;s/.tar.gz .*//g')
wget "http://http.debian.net/debian/pool/main/d/debootstrap/$V.tar.gz" -O - | tar xfz -
ln -nfs "$V" debootstrap
cd debootstrap
#
# minimum patch needed for debootstrap to work in this environment
#
patch << 'EOF' || fallback
--- debootstrap-1.0.91.1/functions	2017-07-25 05:02:27.000000000 +0200
+++ debootstrap-1.0.91/functions	2017-10-16 18:23:46.707005005 +0200
@@ -1083,6 +1083,10 @@
 }

 setup_proc () {
+
+echo setup_proc
+return 0
+
 	case "$HOST_OS" in
 	    *freebsd*)
 		umount_on_exit /dev
@@ -1162,6 +1166,10 @@
 }
 
 setup_devices_simple () {
+
+echo setup_devices_simple
+return 0
+
 	# The list of devices that can be created in a container comes from
 	# src/core/cgroup.c in the systemd source tree.
	mknod -m 666 $TARGET/dev/null	c 1 3
EOF
#
# you can watch the debootstrap progress via
# tail -F $HOME/$ROOTFS_TOP/debootstrap/debootstrap.log
#
DEBOOTSTRAP_DIR=$(pwd)
export DEBOOTSTRAP_DIR
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
    ./debootstrap --foreign --include=apt --arch="$ARCHITECTURE" "$VERSION" "$HOME/$ROOTFS_TOP" http://deb.debian.org/debian \
                                                                || : # proot returns invalid exit status
} # end DO_FIRST_STAGE

#
# =================================================
# second stage - complete the bootstrapping process
#
$DO_SECOND_STAGE && {
#
# place some precrafted templates to avoid execution of adduser, addgroup
# and the like. Since these do not work well in this 
# environment (at least at the time of writing)
#
cat << EOF > "$HOME/$ROOTFS_TOP/etc/passwd"
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
irc:x:39:39:ircd:/var/run/ircd:/usr/sbin/nologin
gnats:x:41:41:Gnats Bug-Reporting System (admin):/var/lib/gnats:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
systemd-timesync:x:100:102:systemd Time Synchronization,,,:/run/systemd:/bin/false
systemd-network:x:101:103:systemd Network Management,,,:/run/systemd/netif:/bin/false
systemd-resolve:x:102:104:systemd Resolver,,,:/run/systemd/resolve:/bin/false
systemd-bus-proxy:x:103:105:systemd Bus Proxy,,,:/run/systemd:/bin/false
_apt:x:104:65534::/nonexistent:/bin/false
messagebus:x:105:110::/var/run/dbus:/bin/false
sshd:x:106:65534::/run/sshd:/usr/sbin/nologin
$USER_NAME:x:$USER_ID:$USER_ID::/home/$USER_NAME:/bin/bash
EOF
chmod 644 "$HOME/$ROOTFS_TOP/etc/passwd"

cat << EOF > "$HOME/$ROOTFS_TOP/etc/group"
root:x:0:
daemon:x:1:
bin:x:2:
sys:x:3:
adm:x:4:
tty:x:5:
disk:x:6:
lp:x:7:
mail:x:8:
news:x:9:
uucp:x:10:
man:x:12:
proxy:x:13:
kmem:x:15:
dialout:x:20:
fax:x:21:
voice:x:22:
cdrom:x:24:
floppy:x:25:
tape:x:26:
sudo:x:27:
audio:x:29:
dip:x:30:
www-data:x:33:
backup:x:34:
operator:x:37:
list:x:38:
irc:x:39:
src:x:40:
gnats:x:41:
shadow:x:42:
utmp:x:43:
video:x:44:
sasl:x:45:
plugdev:x:46:
staff:x:50:
games:x:60:
users:x:100:
nogroup:x:65534:
systemd-journal:x:101:
systemd-timesync:x:102:
systemd-network:x:103:
systemd-resolve:x:104:
systemd-bus-proxy:x:105:
input:x:106:
crontab:x:107:
netdev:x:108:
ssh:x:109:
messagebus:x:110:
$USER_NAME:x:$USER_ID:
EOF
chmod 644 "$HOME/$ROOTFS_TOP/etc/group"

cat << EOF > "$HOME/$ROOTFS_TOP/etc/shadow"
root:*:17448:0:99999:7:::
daemon:*:17448:0:99999:7:::
bin:*:17448:0:99999:7:::
sys:*:17448:0:99999:7:::
sync:*:17448:0:99999:7:::
games:*:17448:0:99999:7:::
man:*:17448:0:99999:7:::
lp:*:17448:0:99999:7:::
mail:*:17448:0:99999:7:::
news:*:17448:0:99999:7:::
uucp:*:17448:0:99999:7:::
proxy:*:17448:0:99999:7:::
www-data:*:17448:0:99999:7:::
backup:*:17448:0:99999:7:::
list:*:17448:0:99999:7:::
irc:*:17448:0:99999:7:::
gnats:*:17448:0:99999:7:::
nobody:*:17448:0:99999:7:::
systemd-timesync:*:17448:0:99999:7:::
systemd-network:*:17448:0:99999:7:::
systemd-resolve:*:17448:0:99999:7:::
systemd-bus-proxy:*:17448:0:99999:7:::
_apt:*:17448:0:99999:7:::
messagebus:*:17448:0:99999:7:::
sshd:*:17448:0:99999:7:::
$USER_NAME:*:15277:0:99999:7:::
EOF
chmod 640 "$HOME/$ROOTFS_TOP/etc/shadow"

#
# add the termux user homedir to the new debian guest system
#
mkdir -p "$HOME/$ROOTFS_TOP/home/$USER_NAME"
chmod 755 "$HOME/$ROOTFS_TOP/home/$USER_NAME"

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
cat << 'EOF' > "$HOME/$ROOTFS_TOP/etc/resolv.conf"
nameserver 208.67.222.222
nameserver 208.67.220.220
EOF
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
