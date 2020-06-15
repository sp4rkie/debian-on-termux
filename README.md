debian-on-termux
================

what is it
----------

- a shell script to install [Debian](https://www.debian.org) via [debootstrap](https://wiki.debian.org/Debootstrap) in a [Termux](https://wiki.termux.com/wiki/Main_Page) environment
- supported Debian versions also include: [Debian testing (bullseye)](https://www.debian.org/releases/testing/), [Debian unstable (sid)](https://www.debian.org/releases/sid/)
- supported architectures include: armel, armhf, arm64, i386, amd64
- no root permissions are required

how to use it
-------------

- install [Termux](https://termux.com/)
- optionally modify the configuration lines near the top of the script
- download `debian_on_termux_10.sh` (or `debian_on_termux.sh` if using an Android version before 10) and run it;

        wget -q https://raw.githubusercontent.com/sp4rkie/debian-on-termux/master/debian_on_termux_10.sh && sh debian_on_termux_10.sh

- Debian will be installed only if it is not already.
- you will be proot-ed to Debian, type exit to return to termux.


alternatives
------------

- [Fedora](https://github.com/nmilosev/termux-fedora)
- [Arch](https://github.com/sdrausty/termux-archlinux)
- [Ubuntu](https://github.com/Neo-Oli/termux-ubuntu)

reference
----------

[termux wiki](https://wiki.termux.com/wiki/Debian)

Issues
-------
Without a pull request are not likely to be addressed. 

