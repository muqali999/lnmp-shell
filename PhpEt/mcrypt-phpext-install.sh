#!/bin/bash

# Check if user is root
if [ $(id -u) != "0" ]; then
    printf "Error: You must be root to run this script!\n"
    exit 1
fi

printf "\n"
printf "==================================\n"
printf " Redis php extension Install      \n"
printf "==================================\n"
printf "\n\n"

if [ ! -s src ]; then    
    printf "Error: directory src not found.\n"
    exit 1
fi

# 定义软件名称和下载网址

#名称
softwareName="mcrypt-1.0.9"
#软件后缀名
softwareSuffix=".tgz"
#扩展模块名称
extModuleName="mcrypt"

#下载网址
downloadUrl="https://pecl.php.net/get/mcrypt-1.0.9.tgz"


#检测PHP是否已安装
if [ ! -f /usr/local/php/bin/php ]; then
    printf "Error: php has not installed! Please compile install PHP7 first.\n"
    exit 1
fi

softwareFullName=$softwareName$softwareSuffix

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

printf "========= $softwareName php extension install start... =========\n\n"

cd $softwareName

export PHP_AUTOCONF="/usr/local/bin/autoconf"
export PHP_AUTOHEADER="/usr/local/bin/autoheader"
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config
make
#make test
make install
cd -

printf "$softwareName installation success!\n"
exit 1

#isExists=`grep 'extension = "$extModuleName.so"' /usr/local/php/etc/php.ini | grep -v ";" | wc -l`
#if [ "$isExists" != "1" ]; then
#    sed -i '/;extension_dir = "ext"/ a\extension = "$extModuleName.so"' /usr/local/php/etc/php.ini
#fi

systemctl restart php-fpm.service
cd -

printf "\n========== $softwareName php extension install Completed! ========\n\n"

/usr/local/php/bin/php -m | grep $extModuleName

printf "============== The End. ==============\n"