#!/bin/bash

# Check if user is root
if [ $(id -u) != "0" ]; then
    printf "Error: You must be root to run this script!\n"
    exit 1
fi


#CentOS所要共享目录路径
SharedPath=" /data/www/htdocs"

#安装vmware tools
dnf -y install open-vm-tools open-vm-tools-desktop
vmware-hgfsclient

#挂载磁盘
vmhgfs-fuse .host:/ $SharedPath -o allow_other

#配置磁盘挂载信息
echo ".host:/	$SharedPath	fuse.vmhgfs-fuse	allow_other	0	0" >> /etc/fstab

printf "============== The End. ==============\n"