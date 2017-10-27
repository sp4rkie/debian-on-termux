debian-on-termux
================

what is it
----------

- a shell script to install [Debian 9 (stretch)](https://www.debian.org/releases/stretch/) via [debootstrap](https://wiki.debian.org/Debootstrap) in a [Termux](https://wiki.termux.com/wiki/Main_Page) environment
- supported Debian versions include: stable (stretch), testing (buster), unstable
- supported architectures include: armel, armhf, arm64, i386, amd64

how to use it
-------------

- install [Termux](https://termux.com/)
- download `debian_on_termux.sh` from [debian-on-termux](https://github.com/sp4rkie/debian-on-termux) in your termux home directory

        cd /data/data/com.termux/files/home
        wget https://raw.githubusercontent.com/sp4rkie/debian-on-termux/master/debian_on_termux.sh

- check the configuration lines near the top of the script for your target architecture, debian version and other preferences
- set file permissions and execute the script

        chmod 755 debian_on_termux.sh
        ./debian_on_termux.sh

- to watch the installation process type

        tail -F $HOME/deboot_debian/debootstrap/debootstrap.log

- if all went well (takes about 30min on the hardware below) a script is created to enter the debian guest system

        $HOME/bin/enter_deb

        Usage: enter_deb [options] [command]
        enter_deb: enter the installed debian guest system

          -0 - mimic root (default)
          -n - prefer regular termux uid (termux-uid)
          -p - mount proc (requires a patched proot package)

- a patched proot package is located [here](https://github.com/termux/termux-packages/issues/1679#issuecomment-338595627)

- for suggestions or in the unlikely event of a problem just raise an issue [here](https://github.com/sp4rkie/debian-on-termux/issues/new):-)

hardware
--------

- developed and tested on Android version: 6.0.1/ Device manufacturer: LGE/ Device model: LG-K100

reference
---------

[How to install Debian 9.2 chroot termux? #1645](https://github.com/termux/termux-packages/issues/1645#issuecomment-337564650)

