# debian-on-termux
shell script to install Debian 9 (stretch) via debootstrap in a termux-app environment

Prerequisites

- install termux-app on your smartphone
- download 'debian_on_termux.sh' to termux home directory '/data/data/com.termux/files/home'
- execute the script

    chmod 755 debian_on_termux.sh
    ./debian_on_termux.sh

- watch the installation process by

    tail -F $HOME/deboot_debian9/debootstrap/debootstrap.log
