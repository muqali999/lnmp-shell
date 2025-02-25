#!/bin/bash

# Check if user is root
if [ $(id -u) != "0" ]; then
    printf "Error: You must be root to run this script!\n"
    exit 1
fi

# 定义软件名称和下载网址

#名称
softwareName="mariadb-10.11.11"
#软件后缀名
softwareSuffix=".tar.gz"

#下载网址
downloadUrl="https://mirrors.xtom.com.hk/mariadb/mariadb-10.11.11/source/mariadb-10.11.11.tar.gz"
#安装路径
targetPath="/usr/local/mysql"

#校验文件
verifiedFilePath="/usr/local/mysql/bin/mysql"

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

#检测依赖软件jemalloc
if [ ! -s /usr/local/lib/libjemalloc.so ]; then
	printf "Error: jemalloc is not installed!\n"
	exit 1
fi

#新建用户目录
groupadd mysql
useradd -g mysql mysql -s /bin/false

if [ ! -d /data/database ]; then
    mkdir -p /data/database
fi

if [ ! -d /var/log/mysql ]; then
	mkdir -m 0777 -p /var/log/mysql
fi

#安装依赖库
#dnf -y install libtirpc ncurses ncurses-devel
#dnf -y install devtoolset-10

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

cd $softwareName
cmake . -DCMAKE_INSTALL_PREFIX=$targetPath -DMYSQL_DATADIR=/data/database/mysql -DSYSCONFDIR=/etc -DMYSQL_UNIX_ADDR=/usr/local/mysql/run/mysql.sock -DMYSQL_TCP_PORT=3306 -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_EXTRA_CHARSETS=all -DWITH_SSL=system -DENABLED_LOCAL_INFILE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_TOKUDB_STORAGE_ENGINE=1 -DWITH_SPIDER_STORAGE_ENGINE=1 -DENABLE_ASSEMBLER=1 -DWITH_BIG_TABLES=1 -DWITH_PLUGIN_ARIA=1 -DWITH_ARIA_TMP_TABLES=1 -DENABLE_THREAD_SAFE_CLIENT=1 -DWITH_READLINE=1 -DWITH_DEBUG=0 -DCMAKE_EXE_LINKER_FLAGS='-ljemalloc' -DFORCE_INSOURCE_BUILD=1
make -j 4

printf "$softwareName compile success!\n"
exit 1

make install
cd -

if [ ! -s $verifiedFilePath ]; then
	printf "Error: $softwareName compile install failed!\n"
	exit 1
fi

cd -

#删除旧的配置文件
if [ -f /etc/my.cnf ]; then
	rm -rf /etc/my.cnf
fi

#创建配置文件
cat >/etc/my.cnf<<EOF
# Mysql config file

# The MySQL server
[mysqld]
user = mysql
port = 3306
basedir = /usr/local/mysql
datadir = /data/database/mysql
socket	= /usr/local/mysql/run/mysql.sock
pid-file = /usr/local/mysql/run/mysqld.pid

#数据编码
character-set-server = utf8mb4
collation-server = utf8mb4_general_ci

#默认存贮引擎设置
default_storage_engine = InnoDB
innodb_file_per_table = 1
#默认值为128M,当MySql服务器配置较低时,可以将参数设小一点.
#innodb_buffer_pool_size = 64M

#Bin Log设置
#server-id = 1
log-bin=mysql-bin
binlog_format = mixed
binlog_expire_logs_seconds = 604800

skip-name-resolve
skip-host-cache
skip-external-locking

query_cache_type = on
query_cache_strip_comments = on
query_cache_size = 64M
query_cache_limit = 2M

tmp_table_size = 256M
max_heap_table_size = 256M
table_open_cache = 512
open_files_limit = 8192

#慢日志设置
log_error = /var/log/mysql/mysql-error.log
long_query_time = 1
slow_query_log
slow_query_log_file = /var/log/mysql/mysql-slow.log

#连接设置
max_connections = 512
bind-address = 127.0.0.1
init_connect = 'SET NAMES utf8mb4'

[client]
default-character-set = utf8mb4
port = 3306
socket = /usr/local/mysql/run/mysql.sock

[mysqldump]
EOF

cd /usr/local/mysql

chown mysql.mysql -R run

#start mysql
./bin/mysqld --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/data/database/mysql
./bin/mysql_ssl_rsa_setup

cp ./support-files/mysql.server /etc/rc.d/init.d/mysqld

chmod 0775 /etc/rc.d/init.d/mysqld

sed -i 's/^basedir=/basedir=\/usr\/local\/mysql/g' /etc/rc.d/init.d/mysqld
sed -i 's/^datadir=/datadir=\/data\/database\/mysql/g' /etc/rc.d/init.d/mysqld

isSet=`grep "/usr/local/mysql/bin" /etc/profile | wc -l`
if [ "$isSet" != "1" ]; then
    echo "export PATH=$PATH:/usr/local/mysql/bin">>/etc/profile
fi

read -p "Are you Sure Current is Virtual Server and Memery is 2G? [y/n]:" isInnodbpool
if [ "$isInnodbpool" == "y" ] || [ "$isInnodbpool" == "Y" ]; then
	sed -i 's/^#innodb_buffer_pool_size = 64M/innodb_buffer_pool_size = 64M/g' /etc/my.cnf
fi

ln -s /usr/local/mysql/lib/mysql /usr/lib/mysql
ln -s /usr/local/mysql/include/mysql /usr/include/mysql

service mysqld start
chkconfig --add mysqld
chkconfig mysqld on

service mysqld restart
cd -

cat /etc/fstab | grep /swapfile
read -p "Do you want create swap partitions?[y/n]:" isSwap
if [ "$isSwap" == "y" ] || [ "$isSwap" == "Y" ]; then
	dd if=/dev/zero of=/swapfile bs=1M count=1024
	mkswap /swapfile
	swapon /swapfile
	echo '/swapfile               swap                    swap    defaults        0 0' >> /etc/fstab
fi

printf "\n========== $softwareName install end =============\n\n"

ps aux | grep mysql | grep -v "grep"
lsof -n | grep jemalloc | grep -v "sh"
systemctl status mysqld.service

printf "============== The End. ==============\n"