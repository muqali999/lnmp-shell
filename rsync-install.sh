#!/bin/bash

# Check if user is root
if [ $(id -u) != "0" ]; then
    printf "Error: You must be root to run this script!\n"
    exit 1
fi

# 定义软件名称和下载网址

#名称
softwareName="rsync-3.4.1"
#软件后缀名
softwareSuffix=".tar.gz"

#下载网址
downloadUrl="https://download.samba.org/pub/rsync/rsync-3.4.1.tar.gz"
#安装路径
targetPath="/usr/local/rsync"

#校验文件
verifiedFilePath="/usr/local/rsync/bin/rsync"

printf "\n"
printf "======================================\n"
printf " $softwareName Install	    \n"
printf "======================================\n"
printf "\n"

if [ ! -s src ]; then    
    printf "Error: directory src not found.\n"
    exit 1
fi

#删除yum安装过的软件旧版本
#apt -y remove rsync

softwareFullName=$softwareName$softwareSuffix

#检测软件是否安装过
if [ -s $verifiedFilePath ]; then
    printf "\n$softwareName has been installed.\n\n";
	exit 1
fi

#安装依赖软件包
apt install libxxhash0 xxhash libxxhash-dev
apt -y install lz4 liblz4-1 liblz4-dev

cd src

printf "\n========= source package download start =========\n\n"

if [ -s $softwareFullName ]; then
    echo "$softwareFullName [found]"
else
    echo "$softwareFullName are downloading now..."
    wget $downloadUrl
fi

if [ -s $softwareName ]; then
	rm -rf $softwareName
fi
tar -zxvf $softwareFullName

printf "\n========= source package download completed =========\n\n"

printf "========= $softwareName install start... =========\n\n"

cd $softwareName
./configure --prefix=$targetPath --disable-xxhash
make

printf "$softwareName compile success!\n"
exit 1

make install
cd -

if [ ! -s $verifiedFilePath ]; then
	printf "Error: $softwareName compile install failed!\n"
	exit 1
fi

cd -

#创建配置文件

mkdir -p /usr/local/rsync/etc
mkdir -m 0777 -p /usr/local/rsync/logs

echo "#username:password">/usr/local/rsync/etc/rsyncd.pass
chmod 600 /usr/local/rsync/etc/rsyncd.pass

if [ -s /usr/local/rsync/etc/rsyncd.conf ]; then
    mv /usr/local/rsync/etc/rsyncd.conf /usr/local/rsync/etc/rsyncd.conf.bak
fi

cat >/usr/local/rsync/etc/rsyncd.conf<<EOF
uid = nobody
gid = nobody
port = 873
use chroot = yes
max connections = 100
pid file = /usr/local/rsync/var/run/rsyncd.pid
log file = /usr/local/rsync/logs/rsyncd.log
list = no
strict modes = no
secrets file = /usr/local/rsync/etc/rsyncd.pass
ignore errors

#hosts allow = IP address
hosts deny=*

#[demo]
#uid = root
#gid = root
#path = /rsync module path
#auth users = username

#read only = no 
EOF

/usr/local/rsync/bin/rsync --daemon --config=/usr/local/rsync/etc/rsyncd.conf

mv ../rsyncd.service.txt /usr/lib/systemd/system/rsyncd.service

systemctl enable rsyncd.service

#随机启动
#isSet=`grep "/usr/local/rsync/bin/rsync --daemon" /etc/rc.local | wc -l`
#if [ "$isSet" == "0" ]; then
    #echo "/usr/local/rsync/bin/rsync --daemon --config=/usr/local/rsync/etc/rsyncd.conf">>/etc/rc.local
#fi

systemctl restart rsyncd.service

printf "\n========== $softwareName install end =============\n\n"

printf "============== The End. ==============\n"