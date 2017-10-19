debian-on-termux
================

what is it
----------

- a shell script to install [Debian 9 (stretch)](https://www.debian.org/releases/stretch/) via [debootstrap](https://wiki.debian.org/Debootstrap) in a [Termux](https://wiki.termux.com/wiki/Main_Page) environment

how to use it
-------------

- install [Termux](https://termux.com/)
- download `debian_on_termux.sh` from [debian-on-termux](https://github.com/sp4rkie/debian-on-termux) in your termux home directory `$HOME`
```
    cd /data/data/com.termux/files/home
    wget https://raw.githubusercontent.com/sp4rkie/debian-on-termux/master/debian_on_termux.sh
```
- set perms and execute the script
```
    chmod 755 debian_on_termux.sh
    ./debian_on_termux.sh
```
- watch the installation process by
```
    tail -F $HOME/deboot_debian9/debootstrap/debootstrap.log
```
- if all went well a script is created in `$HOME/bin`. To enter the debian guest system just type
```
    $HOME/bin/enter_deb
```
- in case of a problem just drop me an email:-)

reference
---------
[How to install Debian 9.2 chroot termux? #1645](https://github.com/termux/termux-packages/issues/1645#issuecomment-337564650)
