debian-on-termux
================

what is it
----------

- a shell script to install [Debian 10 (buster)](https://www.debian.org/releases/buster/) via [debootstrap](https://wiki.debian.org/Debootstrap) in a [Termux](https://wiki.termux.com/wiki/Main_Page) environment
- supported Debian versions also include: [Debian testing (bullseye)](https://www.debian.org/releases/testing/), [Debian unstable (sid)](https://www.debian.org/releases/sid/)
- supported architectures include: armel, armhf, arm64, i386, amd64
- no root permissions are required

how to use it
-------------

- install [Termux](https://termux.com/)
- download `debian_on_termux.sh` from [debian-on-termux](https://github.com/sp4rkie/debian-on-termux) into your termux home directory

        cd /data/data/com.termux/files/home
        apt update
        apt install wget termux-tools
        hash -r
        wget -q https://raw.githubusercontent.com/sp4rkie/debian-on-termux/master/debian_on_termux.sh

- optionally check/modify the configuration lines near the top of the script
- execute the script

        sh debian_on_termux.sh

- to watch the ongoing installation process type

        tail -F $HOME/deboot_debian/debootstrap/debootstrap.log

- after the install this log is moved over to

        $HOME/deboot_debian/var/log/bootstrap.log

- if all went well a script is created to enter the debian guest system

        $HOME/bin/enter_deb

        Usage: enter_deb [options] [command]
        enter_deb: enter the installed debian guest system

          -0 - mimic root (default)
          -n - prefer regular termux uid (termux-uid)

- sample usage: debian shell (stay in chrooted debian)
        
        bash-4.4$ enter_deb
        root@localhost:~#

- sample usage: debian one-shot command (execute in chrooted debian and return to the host environment)

        bash-4.4$ enter_deb -n id\; hostname\; pwd\; cat /etc/debian_\*
        uid=10228(u0_a228) gid=10228(u0_a228) groups=10228(u0_a228),3003,9997,50228
        localhost
        /home/u0_a228
        10.3
        bash-4.4$

alternatives
------------

- [Fedora](https://github.com/nmilosev/termux-fedora)
- [Arch](https://github.com/sdrausty/termux-archlinux)
- [Ubuntu](https://github.com/Neo-Oli/termux-ubuntu)

reference
----------

[How to install Debian 9.2 chroot termux? #1645](https://github.com/termux/termux-packages/issues/1645#issuecomment-337564650)

Issues
-------
Without a pull request are not likely to be addressed. 

