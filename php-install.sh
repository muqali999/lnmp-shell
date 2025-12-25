#!/bin/bash

# Check if user is root
if [ $(id -u) != "0" ]; then
    printf "Error: You must be root to run this script!\n"
    exit 1
fi

# 定义软件名称和下载网址

#名称
softwareName="php-8.4.4"
#软件后缀名
softwareSuffix=".tar.bz2"

#下载网址
downloadUrl="https://www.php.net/distributions/php-8.4.4.tar.bz2"
#安装路径
targetPath="/usr/local"

#校验文件
verifiedFilePath="/usr/local/php/bin/php"

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
tar -jxvf $softwareFullName

printf "\n========= source package download completed =========\n\n"

printf "========= $softwareName install start... =========\n\n"

#安装依懒软件包
apt -y install librabbitmq4 librabbitmq-dev

ldconfig


#centos 7.x
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"
#if [ ! -s /usr/local/lib/pkgconfig/libzip.pc ]; then
#	ln -s /usr/local/lib64/pkgconfig/libzip.pc /usr/local/lib/pkgconfig/libzip.pc
#fi

cd $softwareName
./configure --prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv --with-curl --with-openssl --with-zlib --with-bz2 --with-zip --with-gettext --with-ldap --with-ldap-sasl --with-xsl --without-pear --enable-gd --enable-exif --enable-mbstring --enable-bcmath --enable-shmop --enable-sockets --enable-soap --enable-sysvsem --enable-sysvshm --enable-fpm --enable-pcntl --enable-calendar
make -j 4
make install
cd -

if [ ! -s $verifiedFilePath ]; then
	printf "Error: $softwareName compile install failed!\n"
	exit 1
fi

cd -

printf "\n========== $softwareName install end =============\n\n"

printf "============== The End. ==============\n"