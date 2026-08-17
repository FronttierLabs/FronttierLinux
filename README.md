# FronttierLinux
Smaller than everything that can do what it does.

## What is it?

Fronttier Linux is a from-scratch LFS-based distribution shipped as a
stage tarball like Gentoo. -install IT, Use it, that's it.

- **less than 300MB** Smallest tarbal ever ~ (Gentoo systemd stage: 500+ MB)
- **systemd** and **runit** in one Tarball
- **Full source toolchain**: while keep the size down..
- **will add** a void ENV for FronttierLinux in the near future
- **x86_64 only** (64-bit Intel or AMD)
- 32-bit x86, ARM, and RISC-V are **not supported** yet.


## installation

See the install guide below.

## Source vs release

- **This repo** contains scripts, configs, and docs. 
- **The stage tarball** lives in GitHub Releases. > https://github.com/FronttierLabs/FronttierLinux/tags

## Licenses

- scripts: GPL-3.0-or-later ('LICENSE')
- documentation: CC BY-SA 4.0
- Bundled third-party software: see 'THIRD_PARTY_LICENSES.md'


# Fronttier Linux — Stage Tarball Install Guide (UEFI)

## 1. Boot a live Gentoo ISO (UEFI)

Boot the Gentoo ISO in UEFI mode.
if you have low end hardware like 4gb or less i recommend using mx-linux with xfce to install FronttierLinux

## 2. Download Fronttier
```bash
wget https://github.com/FronttierLabs/FronttierLinux/releases/download/oposum_v0.34/fronttier.tar.xz #Download in working directory
```

## 3. Pick the target disk
```bash
sudo -i
lsblk          # confirm the disk name, e.g. /dev/sda or /dev/nvme0n1 or /dev/vda
```
## 4. Partition the disk (UEFI) if not UEFI see how to install for legacy in 34
```bash
cfdisk /dev/sdX          # create:
                         #   Type: EFI System Partition, size >= 512MM
                         #   Type: Linux filesystem,    size >= 10G

export DISK=/dev/sdX            #if nvme you want to do /dev/nvme0n1

export PART1=${DISK}1 MUST BE EFI # or ${DISK}p1 for nvme
export PART2=${DISK}2 MUST BE ROOT # or ${DISK}p2

mkfs.fat  -F32 -n ESP  "$PART1"
mkfs.ext4 -L FronttierRoot -F   "$PART2"
```
## 6. Extract and mount disks
```bash
mount "$PART2" /mnt
mkdir -p /mnt/boot/efi
mount "$PART1" /mnt/boot/efi
tar -xJpf fronttier.tar.xz -C /mnt --numeric-owner
```
### MUST DO. create the excluded mount points BEFORE chroot binds
```bash
mkdir -p /mnt/{proc,sys,dev,run,tmp,mnt,media}
chmod 1777 /mnt/tmp
```
## 7. Chroot
```bash
mount --rbind /dev  /mnt/dev 
mount --make-rslave /mnt/dev
mount --rbind /sys  /mnt/sys
mount --make-rslave /mnt/sys
mount --rbind /proc /mnt/proc
mount --make-rslave /mnt/proc
mount -t tmpfs tmpfs /mnt/run

cp /etc/resolv.conf /mnt/etc/resolv.conf
chroot /mnt /bin/bash        # bash is on the host; zsh is not in the base tarball
```
## 8. Configure (inside chroot)
```bash
echo "hostname" > /etc/hostname
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime # or your time zone

passwd root                  # set a real password, default passwd is 123

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

groupadd storage
useradd -m -G wheel,audio,video,storage -s /bin/bash user
passwd user
```
## 9. Write fstab (inside chroot)
```bash
ROOT_DEV=$(findmnt -n -o SOURCE /)
ROOT_PARTUUID=$(blkid -s PARTUUID -o value "$ROOT_DEV")

ESP_DEV=$(findmnt -n -o SOURCE /boot/efi)
ESP_PARTUUID=$(blkid -s PARTUUID -o value "$ESP_DEV")

cat > /etc/fstab <<EOF
PARTUUID=$ROOT_PARTUUID /          ext4  defaults,noatime  0 1
PARTUUID=$ESP_PARTUUID /boot/efi  vfat  defaults          0 2

proc        /proc            proc     nosuid,noexec,nodev  0 0
sysfs       /sys             sysfs    nosuid,noexec,nodev  0 0
devtmpfs    /dev             devtmpfs mode=0755,nosuid     0 0
devpts      /dev/pts         devpts   gid=5,mode=620       0 0
tmpfs       /run             tmpfs    defaults             0 0
tmpfs       /dev/shm         tmpfs    nosuid,nodev         0 0
cgroup2     /sys/fs/cgroup   cgroup2  nosuid,noexec,nodev  0 0
EOF
```
## 10. Bootloader 'grub' (inside chroot)
```bash
chmod -x /etc/grub.d/10_linux

cat > /etc/grub.d/40_custom <<'EOF'
#!/bin/sh
ROOT_PART="$(findmnt -n -o SOURCE /)"
FS_UUID="$(blkid -s UUID -o value "$ROOT_PART")"
PARTUUID="$(blkid -s PARTUUID -o value "$ROOT_PART")"
KERNEL="$(ls -1 /boot/vmlinuz-*fronttier* 2>/dev/null | sort -V | tail -1 | xargs basename)"
[ -n "$KERNEL" ] || KERNEL="$(ls -1 /boot/vmlinuz-* 2>/dev/null | sort -V | tail -1 | xargs basename)"

cat <<GRUBENTRY
menuentry "Fronttier Linux (Systemd)" {
    insmod part_gpt
    insmod ext2
    search --no-floppy --fs-uuid --set=root $FS_UUID
    linux /boot/$KERNEL root=PARTUUID=$PARTUUID ro quiet
}

menuentry "Fronttier Linux (Runit)" {
    insmod part_gpt
    insmod ext2
    search --no-floppy --fs-uuid --set=root $FS_UUID
    linux /boot/$KERNEL root=PARTUUID=$PARTUUID ro init=/usr/bin/runit-init quiet
}
GRUBENTRY
EOF
```
## Just to be sure its executable run :
```bash
chmod +x /etc/grub.d/40_custom


grub-install --target=x86_64-efi \
             --efi-directory=/boot/efi \
             --bootloader-id=Fronttier \
             --recheck --removable

grub-mkconfig -o /boot/grub/grub.cfg

exit
```
## 11. Reboot and boot on FronttierLinux
```bash
umount -R /mnt 
reboot
```

## 12. remove the USB boot onto the INIT of your choice

dau rm -rf /* # ;)

### optional

- after login of the non root user you **must** setup ZSH 

# FronttierLinux Legacy install


## 1. Boot a live ISO with legacy support

MX-Linux/Anything with legacy support
if you have low end hardware, 4gb of ram or less i recommand using mx-linux with xfce to install FronttierLinux

## 2. Download Fronttier
```bash
wget https://github.com/FronttierLabs/FronttierLinux/releases/download/oposum_v0.34/fronttier.tar.xz #Download in working directory
```

## 3. Pick the target disk
```bash
sudo su  # default passwd of mx-linux is "demo"
lsblk          # confirm the disk name, e.g. /dev/sda or /dev/nvme0n1 or /dev/vda
```
## 4. Partition the disk (LEGACY)
```bash
cfdisk /dev/sdX          # create: must also do dos lable type
                         #   Type: SWAP/SOLARIS System Partition, size >= 2G
                         #   Type: Linux filesystem,    size >= 5G

export DISK=/dev/sdX            #if nvme you want to do /dev/nvme0n1, if /dev/vda change to /dev/vda
```
- **IF YOU DONT HAVE A SWAP PARTITION SEE INSCTRCUTION BELOW
```bash
export PART1=${DISK}1 MUST BE SWAP # or ${DISK}p1 
```
- ** if you didnt want or make a swap partition just do the command above and skip the one below
```bash
export PART2=${DISK}2 MUST BE ROOT # or ${DISK}p2
```


-**IF YOU DIDNT CONFIGURE A SWAP PARTITION REPLACE THE 2 to 1**
```bash
mkswap "$PART1" 
mkfs.ext4 -L FronttierRoot -F   "$PART2"
```
## 6. Extract and mount disks
```bash
mount "$PART2" /mnt
mkdir -p /mnt/boot/efi
mount "$PART1" /mnt/boot/efi
tar -xJpf fronttier.tar.xz -C /mnt --numeric-owner
```
### MUST DO. create the excluded mount points BEFORE chroot binds
```bash
mkdir -p /mnt/{proc,sys,dev,run,tmp,mnt,media}
chmod 1777 /mnt/tmp
```
## 7. Chroot
```bash
mount --rbind /dev  /mnt/dev 
mount --make-rslave /mnt/dev
mount --rbind /sys  /mnt/sys
mount --make-rslave /mnt/sys
mount --rbind /proc /mnt/proc
mount --make-rslave /mnt/proc
mount -t tmpfs tmpfs /mnt/run

cp /etc/resolv.conf /mnt/etc/resolv.conf

chroot /mnt /bin/bash        # bash is on the host; zsh is not in the base tarball
```
## 8. Configure (inside chroot)
```bash
echo "hostname" > /etc/hostname
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime # or your time zone

passwd root                  # set a real password, default passwd is 123

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

groupadd storage
useradd -m -G wheel,audio,video,storage -s /bin/bash user
passwd user
```
## 9. Write fstab (inside chroot)
```bash

ROOT_DEV=$(findmnt -n -o SOURCE /)
ROOT_PARTUUID=$(blkid -s PARTUUID -o value "$ROOT_DEV")

cat > /etc/fstab <<EOF
PARTUUID=$ROOT_PARTUUID /          ext4  defaults,noatime  0 1

proc        /proc            proc     nosuid,noexec,nodev  0 0
sysfs       /sys             sysfs    nosuid,noexec,nodev  0 0
devtmpfs    /dev             devtmpfs mode=0755,nosuid     0 0
devpts      /dev/pts         devpts   gid=5,mode=620       0 0
tmpfs       /run             tmpfs    defaults             0 0
tmpfs       /dev/shm         tmpfs    nosuid,nodev         0 0
cgroup2     /sys/fs/cgroup   cgroup2  nosuid,noexec,nodev  0 0
EOF

cat /etc/fstab
```
## 10. Bootloader 'grub' (inside chroot)
```bash
chmod -x /etc/grub.d/10_linux

cat > /etc/grub.d/40_custom <<'EOF'
#!/bin/sh
ROOT_PART="$(findmnt -n -o SOURCE /)"
FS_UUID="$(blkid -s UUID -o value "$ROOT_PART")"
PARTUUID="$(blkid -s PARTUUID -o value "$ROOT_PART")"
KERNEL="$(ls -1 /boot/vmlinuz-*fronttier* 2>/dev/null | sort -V | tail -1 | xargs basename)"
[ -n "$KERNEL" ] || KERNEL="$(ls -1 /boot/vmlinuz-* 2>/dev/null | sort -V | tail -1 | xargs basename)"

PTTYPE="$(blkid -s PTTYPE -o value "$ROOT_PART")"
if [ "$PTTYPE" = dos ]; then
    PARTMOD=part_msdos
else
    PARTMOD=part_gpt
fi

cat <<GRUBENTRY
menuentry "Fronttier Linux (Systemd)" {
    insmod $PARTMOD
    insmod ext2
    search --no-floppy --fs-uuid --set=root $FS_UUID
    linux /boot/$KERNEL root=PARTUUID=$PARTUUID ro quiet
}

menuentry "Fronttier Linux (Runit)" {
    insmod $PARTMOD
    insmod ext2
    search --no-floppy --fs-uuid --set=root $FS_UUID
    linux /boot/$KERNEL root=PARTUUID=$PARTUUID ro init=/usr/bin/runit-init quiet
}
GRUBENTRY
EOF
```
## Just to be sure its executable run :
```bash
chmod +x /etc/grub.d/40_custom


ROOT_DEV=$(findmnt -n -o SOURCE /)
BIOS_DISK=$(lsblk -no PKNAME "$ROOT_DEV")

grub-install --target=i386-pc --recheck "/dev/$BIOS_DISK"

grub-mkconfig -o /boot/grub/grub.cfg

exit
```
## 11. Reboot and boot on FronttierLinux
```bash
umount -R /mnt 
reboot
```

## 12. remove the USB boot onto the INIT of your choice

dau rm -rf /* # ;)

### optional

after login of the non root user you must setup ZSH 
