#!/bin/bash

# Check if user is root
if [ $(id -u) != "0" ]; then
    printf "Error: You must be root to run this script!\n"
    exit 1
fi

# 定义软件名称和下载网址

#名称
softwareName="redis-7.4.2"
#软件后缀名
softwareSuffix=".tar.gz"

#下载网址
downloadUrl="https://github.com/redis/redis/archive/refs/tags/7.4.2.tar.gz"
#安装路径
targetPath="/usr/local/redis"

#校验文件
verifiedFilePath="/usr/local/redis/bin/redis-server"

printf "\n"
printf "======================================\n"
printf " $softwareName Install	    \n"
printf "======================================\n"
printf "\n"

if [ ! -s src ]; then    
    printf "Error: directory src not found.\n"
    exit 1
fi

softwareFullName=$softwareName$softwareSuffix

#检测软件是否安装过
if [ -s $verifiedFilePath ]; then
    printf "\n$softwareName has been installed.\n\n";
	exit 1
fi

groupadd redis
useradd -g redis redis -s /bin/false

mkdir -p /data/cache/redis
chown -R redis:redis /data/cache/redis

mkdir -p /data/logs/redis
chmod 0777 -R /data/logs/redis

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

yum -y install tcl

cd $softwareName
#./configure --prefix=$targetPath
make
make test

printf "$softwareName compile success!\n"
exit 1

make install PREFIX=$targetPath

#生成配置文件
mkdir -p /usr/local/redis/etc

if [ -s /usr/local/redis/etc/redis.conf ]; then
    rm /usr/local/redis/etc/redis.conf
fi
cp ./redis.conf /usr/local/redis/etc/redis.conf

cd -

if [ ! -s $verifiedFilePath ]; then
	printf "Error: $softwareName compile install failed!\n"
	exit 1
fi

cd -

#设置配置文件
if [ ! -d /data/cache/redis/var/run ]; then
	mkdir -m 0777 -p /data/cache/redis/var/run
	chown -R redis:redis /data/cache/redis/var/run
fi

sed -i 's/^daemonize no/daemonize yes/g' /usr/local/redis/etc/redis.conf
sed -i 's/^dir .\//dir \/data\/redis/g' /usr/local/redis/etc/redis.conf
sed -i 's/^logfile ""/logfile \/var\/log\/redis\/redislog/g' /usr/local/redis/etc/redis.conf
sed -i 's/^pidfile \/var\/run\/redis_6379.pid/pidfile \/data\/redis\/var\/run\/redis_6379.pid/g' /usr/local/redis/etc/redis.conf

sed -i 's/^# unixsocket \/run\/redis.sock/unixsocket \/data\/redis\/var\/run\/redis.sock/g' /usr/local/redis/etc/redis.conf
sed -i 's/^# unixsocketperm 700/unixsocketperm 755/g' /usr/local/redis/etc/redis.conf

isExists=`grep 'vm.overcommit_memory' /etc/sysctl.conf | wc -l`
if [ "$isExists" != "1" ]; then
	echo "vm.overcommit_memory = 1">>/etc/sysctl.conf
	sysctl -p
fi

#生成随机启机服务文件
if [ -s /usr/lib/systemd/system/redis.service ]; then
    rm -rf /usr/lib/systemd/system/redis.service
fi
mv ../redis.service.txt /usr/lib/systemd/system/redis.service

systemctl daemon-reload
systemctl start redis.service

systemctl enable redis.service

ln -s /usr/local/redis/bin/redis-server /usr/bin/redis-server
ln -s /usr/local/redis/bin/redis-cli /usr/bin/redis

systemctl restart redis.service

ps aux | grep redis | grep -v "grep"
netstat -ntlp

printf "\n========== $softwareName install end =============\n\n"

printf "============== The End. ==============\n"