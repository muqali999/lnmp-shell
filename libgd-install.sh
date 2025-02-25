#!/bin/bash

# Check if user is root
if [ $(id -u) != "0" ]; then
    printf "Error: You must be root to run this script!\n"
    exit 1
fi

# 定义软件名称和下载网址

#名称
softwareName="libgd-2.3.3"
#软件后缀名
softwareSuffix=".tar.gz"

#下载网址
downloadUrl="https://fossies.org/linux/www/libgd-2.3.3.tar.gz"
#安装路径
targetPath="/usr/local"

#校验文件
verifiedFilePath="/usr/local/lib/libgd.so"

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
#yum -y remove gd gd-devel

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

cd -

printf "\n========== $softwareName install end =============\n\n"

printf "============== The End. ==============\n"