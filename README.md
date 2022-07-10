# Pi Provisioning

This repository contains tools and scripts that help provision Raspberry Pis.

## Features

- Copy the ISO file to SD card
- Allocate IP address to Pi
- Provision NFS
- Create user-data file on Pi
    - Creates user and sets password
    - Mounts NFS storage
- Create DNS A record in Pihole for the Pi

## Set up NFS Server

```bash
sudo apt install nfs-kernel-server
sudo mkdir -p /srv/nfs4/pi-share
sudo mkdir -p /srv/nfs4/pi-1
sudo echo "/srv/nfs4        gss/krb5i(rw,sync,fsid=0,crossmnt,no_subtree_check)" >> /etc/exports
```

## Debugging user-data

Its preferable to start with a fresh OS to test cloud-init. 
As SD cards have a finite number of writes, you won't be able to keep reinstalling the OS.

The easiest way I've found is to use the AWS CLI to spin up EC2 instances.

```bash
aws ec2 run-instances --image-id <ID> --instance-type <ARM type>\
    --key-name <my-key-pair> --subnet-id <subnet> --security-group-ids <sec group> \
    --user-data file://user-data
```
