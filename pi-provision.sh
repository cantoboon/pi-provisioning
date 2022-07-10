#!/bin/bash +x

# Script that provisions a Raspberry Pi SD card
#
# Format inspired by https://sh.rustup.rs

# Constants
ubuntu_version=22.04
image="ubuntu-${ubuntu_version}-preinstalled-server-arm64+raspi.img.xz"
cache_file="$HOME/.cache/pi-provision/${image}" # Where to store a cached copy of the image

# Args
device=$1 # Eg. /dev/sde
pi_id=$2  # Eg. 1, 2, 3, etc

# Derived settings
hostname="pi-${pi_id}"
ip_address="192.168.0.${pi_id}"

# Master (where this should be run) settings
master_ip=$(ip addr | grep "192.168" | cut -d' ' -f6 | cut -d'/' -f1)

info() {
    printf "\e[34m[INFO]\e[0m $1\n"
}

error() {
    printf "\e[31m[ERROR]\e[0m $1\n"
    exit 1
}

main() {
    check_user
    check_args
    get_image

    ## Copy ISO
    info "Copying image to SD card ${device}"
    # xzcat ~/.cache/pi-provision/${image} | sudo dd of=/dev/sde status=progress bs=4M || error "Failed to copy ISO to SD card"
    info "Copy complete"

    # Mount partitions
    info "Mounting boot partition of ${device} to /media/boot"
    sudo mount ${device}1 /media/boot/ || error "Failed to mount boot partition"
    info "Successfully mounted boot partition"
    info "Mounting main partition of ${device} to /media/micro"
    sudo mount ${device}2 /media/micro/ || error "Failed to mount main partition"
    info "Successfully mounted main parition"

    # Copy the user-data
    info "Copying user-data to boot partition"
    envsubst < user-data.template > /media/boot/user-data || error "Failed to copy user-data"
    info "Copy compete"

    # Unmount the partitions
    info "Unmounting partitions"
    sudo unmount /media/boot /media/micro/ || error "Failed to unmount partition"

    # Setup server NFS - https://linuxize.com/post/how-to-install-and-configure-an-nfs-server-on-ubuntu-20-04/
    info "Creating NFS mount"
    sudo mkdir -p /srv/nfs/${pi_id} || error "Failed to create NFS directory"
    echo "/srv/nfs4/pi-${pi_id} ${ip_address}(rw,sync,no_subtree_check)" >> /etc/exports || error "Failed to create NFS /etc/exports config"
    sudo exportfs -ar || error "Failed to reload NFS config"
    info "NFS mount created successfully"

    info "SD card provisioned successfully. Finished."
}

check_user() {
    if [[ $UID != 0 ]]; then
        error "Script must be run as root."
    fi
}

check_args() {
    if [[ -z $device && -z $pi_id ]]; then
        usage
    fi
}

get_image() {
    if [ ! -f $cache_file ]; then
        info "Cached image doesn't exist. Downloading to ${cache_file}"
        curl -fsS --create-dirs https://cdimage.ubuntu.com/releases/${ubuntu_version}/release/${image} -o ${cache_file} || error "Failed to download image"
        info "Download complete."
    else
        info "Using cached image (${cache_file})"
    fi
}

usage() {
    cat 1>&2 <<EOF
USAGE:
    sudo pi-provision <device> <pi id>

ARGUMENTS:
    device - The Linux device under /dev/. Eg. /dev/sde
    pi id - The numerical ID of the Pi. This is used for the hostname and the NFS share.
EOF
    exit 1
}

main "$@" || exit 1