# debian-on-termux
shell script to install Debian 9 (stretch) via debootstrap in a termux-app environment

what to do:

- install termux-app on your smartphone
- download 'debian_on_termux.sh' from this repository to termux home directory '/data/data/com.termux/files/home'

    wget https://raw.githubusercontent.com/sp4rkie/debian-on-termux/master/debian_on_termux.sh

- set perms and execute the script

    chmod 755 debian_on_termux.sh
    ./debian_on_termux.sh

- watch the installation process by

    tail -F $HOME/deboot_debian9/debootstrap/debootstrap.log
