#!/bin/bash

# kiwi functions
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

set -xe

is_nvidia=false
if [ "$kiwi_profiles" == "with-KDE-nvidia" ] || [ "$kiwi_profiles" == "with-GNOME-nvidia" ]
then
	is_nvidia=true
fi

# install input methods and some fonts for fallback
set +e
zypper -n --gpg-auto-import-keys install 'google-noto-*' 'noto-*-fonts' 'ibus-*'
status_code=$?
if [ "$status_code" != "107" ] && [ "$status_code" != "0" ]
then
	echo zypper -n --gpg-auto-import-keys install 'google-noto-*' 'noto-*-fonts' 'ibus-*' exited with $status_code
	exit 1
fi
set -e

# manpages
zypper -n --gpg-auto-import-keys install man man-pages

# install nvidia drivers
if $is_nvidia
then
	zypper -n clean -a
	zypper -n --gpg-auto-import-keys install --auto-agree-with-licenses nvidia-video-G06 nvidia-video-G06-32bit nvidia-gl-G06 nvidia-gl-G06-32bit nvidia-compute-G06 nvidia-compute-G06-32bit nvidia-compute-utils-G06 2>/dev/null 1>/dev/null

	# mark all nvidia devices witih uaccess
	idx=0
	while [ $idx -lt 128 ]
	do
		echo "L /run/udev/static_node-tags/uaccess/nvidia${idx} - - - - /dev/nvidia${idx}" >> /usr/lib/tmpfiles.d/nvidia-logind-acl-trick-G06-ext.conf
		idx=$((idx + 1))
	done
fi

zypper -n clean -a

# disable root
passwd -l root
# steamos update dummys sudoer file is 99
echo '%wheel  ALL=(ALL)       ALL' > /etc/sudoers.d/98_deck_pw_sudo
sed -i'' '/^ALL   ALL=(ALL) ALL/d' /etc/sudoers
sed -i'' '/^Defaults targetpw/d' /etc/sudoers

# configure snapper as https://build.opensuse.org/package/show/openSUSE:Factory/openSUSE-MicroOS would
cp /usr/share/snapper/config-templates/default /etc/snapper/configs/root

sed -i'' 's/^TIMELINE_CREATE=.*$/TIMELINE_CREATE="no"/g' /etc/snapper/configs/root
sed -i'' 's/^NUMBER_LIMIT=.*$/NUMBER_LIMIT="2-10"/g' /etc/snapper/configs/root
sed -i'' 's/^NUMBER_LIMIT_IMPORTANT=.*$/NUMBER_LIMIT_IMPORTANT="4-10"/g' /etc/snapper/configs/root

baseUpdateSysConfig /etc/sysconfig/snapper SNAPPER_CONFIGS root

# toggle some services
systemctl enable NetworkManager
systemctl disable sshd
systemctl disable firewalld

# force ibus
echo 'export GTK_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus' >> /etc/skel/.profile

# default to nano
echo 'export EDITOR=nano' >> /etc/skel/.profile

cp /etc/skel/.profile /home/katharine/.profile
chown katharine:katharine /home/katharine/.profile

# cups access from group wheel
sed -i'' 's/^SystemGroup root/SystemGroup wheel/' /etc/cups/cups-files.conf
