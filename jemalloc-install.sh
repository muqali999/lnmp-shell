#!/bin/bash

# Check if user is root
if [ $(id -u) != "0" ]; then
    printf "Error: You must be root to run this script!\n"
    exit 1
fi

# 定义软件名称和下载网址

#名称
softwareName="jemalloc-5.3.0"
#软件后缀名
softwareSuffix=".tar.bz2"

#下载网址
downloadUrl="https://github.com/jemalloc/jemalloc/releases/download/5.3.0/jemalloc-5.3.0.tar.bz2"
#安装路径
targetPath="/usr/local"

#校验文件
verifiedFilePath="/usr/local/lib/libjemalloc.so"

printf "\n"
printf "======================================\n"
printf " $softwareName Install	    \n"
printf "======================================\n"
printf "\n"

if [ ! -s websrc ]; then    
    printf "Error: directory websrc not found.\n"
    exit 1
fi

#删除yum安装过的软件旧版本
#yum -y remove jemalloc jemalloc-devel

softwareFullName=$softwareName$softwareSuffix

#检测软件是否安装过
if [ -s $verifiedFilePath ]; then
    printf "\n$softwareName has been installed.\n\n";
	#exit 1
fi

cd websrc

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
tar -jxvf $softwareFullName

printf "\n========= source package download completed =========\n\n"

printf "========= $softwareName install start... =========\n\n"

cd $softwareName
./configure --prefix=$targetPath
make -j 4

printf "$softwareName compile success!\n"
exit 1

make install
cd -

if [ ! -s $verifiedFilePath ]; then
	printf "Error: $softwareName compile install failed!\n"
	exit 1
fi

isSet=`grep "/usr/local/lib" /etc/ld.so.conf | wc -l`
if [ "$isSet" != "1" ]; then
   echo "/usr/local/lib">>/etc/ld.so.conf
fi
ldconfig

if [ -s /usr/lib64/libjemalloc.so ]; then
	rm -rf /usr/lib64/libjemalloc.so
fi
ln -s /usr/lib64/libjemalloc.so /usr/local/lib/libjemalloc.so

cd -

printf "\n========== $softwareName install end =============\n\n"

printf "============== The End. ==============\n"