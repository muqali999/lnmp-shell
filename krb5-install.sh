#!/bin/bash

# Check if user is root
if [ $(id -u) != "0" ]; then
    printf "Error: You must be root to run this script!\n"
    exit 1
fi

# 定义软件名称和下载网址

#名称
softwareName="krb5-1.19.1"
#软件后缀名
softwareSuffix=".tar.gz"

#下载网址
downloadUrl="https://kerberos.org/dist/krb5/1.19/krb5-1.19.1.tar.gz"
#安装路径
targetPath="/usr/local"

#校验文件
verifiedFilePath="/usr/local/lib/krb5/plugins/tls/k5tls.so"

printf "\n"
printf "======================================\n"
printf " $softwareName Install	    \n"
printf "======================================\n"
printf "\n"

if [ ! -s websrc ]; then    
    printf "Error: directory websrc not found.\n"
    exit 1
fi

softwareFullName=$softwareName$softwareSuffix

#检测软件是否安装过
if [ -s $verifiedFilePath ]; then
    printf "\n$softwareName has been installed.\n\n";
	exit 1
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
tar -zxvf $softwareFullName

printf "\n========= source package download completed =========\n\n"

printf "========= $softwareName install start... =========\n\n"

cd $softwareName/src
LDFLAGS='-L/usr/' ./configure --prefix=$targetPath
make
make install

rm -rf /usr/lib64/libk5crypto.so.3
cp lib/libk5crypto.so.3 /usr/lib64/

cd -

if [ ! -s $verifiedFilePath ]; then
	printf "Error: $softwareName compile install failed!\n"
	exit 1
fi

cd -

printf "\n========== $softwareName install end =============\n\n"

printf "============== The End. ==============\n"