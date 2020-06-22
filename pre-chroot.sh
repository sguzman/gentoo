#!/bin/bash -x

# Exit on first fail
set -e

# Following Mental Outlaw's Intalling Gentoo video
echo 'Gentoo Installation script'

# Set up partition scheme for Gentoo
#fdisk /dev/sda

# to create the partitions programatically (rather than manually)
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can 
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "default" will send a empty
# line terminated with a newline to take the cfdisk default.
(
  echo o # clear the in memory partition table
  echo n # new partition
  echo p # primary partition
  echo 1 # partition number 1
  echo   # default - start at beginning of disk
  echo +128M # 100 MB boot parttion
  echo n # new partition
  echo p # primary partition
  echo 2 # partion number 2
  echo   # default, start immediately after preceding partition
  echo   # default, extend partition to end of disk
  echo a # make a partition bootable
  echo 1 # bootable partition is partition 1 -- /dev/sda1
  echo p # print the in-memory partition table
  echo w # write the partition table
  echo q # and we're done
 ) | fdisk /dev/sda

# Format partitions
mkfs.ext4 /dev/sda1
mkfs.ext4 /dev/sda2

# Mount freshly made partition on current host
mount /dev/sda2 /mnt/gentoo
mkdir /mnt/gentoo/boot/
mount /dev/sda1 /mnt/gentoo/boot

cd /mnt/gentoo
# Download hardened Stage 3 Tar

wget --debug --verbose -O stage3-amd64.tar.xz 'http://gentoo.mirrors.tera-byte.com/releases/amd64/autobuilds/current-stage3-amd64/stage3-amd64-20200621T214503Z.tar.xz'
#UnTar Stage 3
tar xpvf stage3-amd64.tar.xz --xattrs-include='*.*' --numeric-owner

ntpd -q -g

mkdir --verbose --parents /mnt/gentoo/etc/portage/defaults
mv --verbose /mnt/gentoo/etc/portage/make.conf /mnt/gentoo/etc/portage/defaults/
cp --verbose /root/local/my.minimal.conf /mnt/gentoo/etc/portage/make.conf

mirrorselect --servers 5 --deep --debug 9 --country 'USA' --output >> /mnt/gentoo/etc/portage/make.conf

mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
cp --verbose --dereference /etc/resolv.conf /mnt/gentoo/etc/resolv.conf

mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

cp --verbose /root/local/chroot.sh /mnt/gentoo/chroot.sh
chmod +x /mnt/gentoo/chroot.sh

echo 'Done here' 
