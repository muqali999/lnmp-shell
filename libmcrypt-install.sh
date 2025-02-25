#!/bin/bash

# Check if user is root
if [ $(id -u) != "0" ]; then
    printf "Error: You must be root to run this script!\n"
    exit 1
fi

# 定义软件名称和下载网址

#名称
softwareName="libmcrypt-2.5.8"
#软件后缀名
softwareSuffix=".tar.gz"

#下载网址
downloadUrl="https://webwerks.dl.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz"
#安装路径
targetPath="/usr/local"

#校验文件
verifiedFilePath="/usr/local/lib/libmcrypt.so"

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
#yum -y remove libmcrypt libmcrypt-devel libtomcrypt

softwareFullName=$softwareName$softwareSuffix

#检测软件是否安装过
if [ -s $verifiedFilePath ]; then
    printf "\n$softwareName has been installed.\n\n";
	exit 1
fi

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
./configure --prefix=$targetPath
make

printf "$softwareName compile success!\n"
exit 1

make install
cd -

if [ ! -s $verifiedFilePath ]; then
	printf "Error: $softwareName compile install failed!\n"
	exit 1
fi

isSet=`grep "/usr/lib" /etc/ld.so.conf | wc -l`
if [ "$isSet" != "1" ]; then
    echo "/usr/lib">>/etc/ld.so.conf    
fi
isSet2=`grep "/usr/lib64" /etc/ld.so.conf | wc -l`
if [ "$isSet2" != "1" ]; then
    echo "/usr/lib64">>/etc/ld.so.conf
fi

isSet3=`grep "/usr/local/lib" /etc/ld.so.conf | wc -l`
if [ "$isSet3" != "1" ]; then
    echo "/usr/local/lib">>/etc/ld.so.conf
fi
isSet4=`grep "/usr/local/lib64" /etc/ld.so.conf | wc -l`
if [ "$isSet4" != "1" ]; then
    echo "/usr/local/lib64">>/etc/ld.so.conf
fi
ldconfig

cd -

printf "\n========== $softwareName install end =============\n\n"

printf "============== The End. ==============\n"