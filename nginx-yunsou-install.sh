#!/bin/bash

# Check if user is root
if [ $(id -u) != "0" ]; then
    printf "Error: You must be root to run this script!\n"
    exit 1
fi

# 定义软件名称和下载网址

#名称
softwareName="nginx-1.20.1"
#软件后缀名
softwareSuffix=".tar.gz"

#下载网址
downloadUrl="http://nginx.org/download/nginx-1.20.1.tar.gz"

#校验文件
verifiedFilePath="/usr/local/nginx/sbin/nginx"

printf "\n"
printf "======================================\n"
printf " $softwareName Install	    \n"
printf "======================================\n"
printf "\n"

if [ ! -s websrc ]; then    
    printf "Error: directory websrc not found.\n"
    exit 1
fi

#检测软件是否安装过
if [ -s $verifiedFilePath ]; then
    printf "\n$softwareName has been installed.\n\n";
	exit 1
fi

if [ ! -f nginx.service.txt ]; then
    printf "the file nginx.service.txt is not exists!\n"
	exit 1
fi

#创建目录

groupadd www
useradd -g www www -s /bin/false

mkdir -p /www
mkdir -p /www/htdocs/default
mkdir -p /www/crontab
mkdir -p /www/logs
mkdir -p /www/cache
mkdir -p /www/tmp
chown -R www:www /www
chmod 0755 -R /www
chmod 0775 -R /www/logs

mkdir -m 0777 -p /var/log/nginx /www/logs/nginx
chown www.www -R /var/log/nginx /www/logs/nginx

mkdir -m 0777 -p /www/cache/nginx_proxy_cache /www/cache/nginx_proxy_temp
chown www.www -R /www/cache/nginx_proxy_cache /www/cache/nginx_proxy_temp

cd websrc

softwareFullName=$softwareName$softwareSuffix

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

#下载云锁插件
wget https://codeload.github.com/yunsuo-open/nginx-plugin/zip/master -O nginx-plugin-master.zip

unzip nginx-plugin-master.zip

wget http://labs.frickle.com/files/ngx_cache_purge-2.3.tar.gz

tar -zxvf ngx_cache_purge-2.3.tar.gz

printf "\n========= source package download completed =========\n\n"

printf "========= $softwareName install start... =========\n\n"

cd $softwareName
./configure --prefix=/usr/local/nginx --user=www --group=www --without-http_memcached_module --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-file-aio --with-http_gunzip_module --with-http_gzip_static_module --with-http_sub_module --with-http_addition_module --with-http_realip_module --with-http_image_filter_module --with-http_mp4_module --with-http_flv_module --with-stream --with-stream_ssl_module --with-ld-opt="-ljemalloc" --with-pcre=../pcre-8.45 --with-openssl=../openssl-1.1.1k --with-zlib=../zlib-1.2.11 --add-module=../nginx-sticky-module --add-module=../ngx_cache_purge-2.3 --add-module=../nginx-plugin-master
make
make install
cd -

if [ ! -s $verifiedFilePath ]; then
	printf "Error: $softwareName compile install failed!\n"
	exit 1
fi

mkdir -p /usr/local/nginx/domains
mkdir -p /usr/local/nginx/ssl

mv ../nginx.service.txt /usr/lib/systemd/system/nginx.service

systemctl enable nginx.service
systemctl status nginx.service
systemctl start nginx.service

cd -

ps aux | grep nginx | grep -v "grep"
lsof -n | grep jemalloc | grep -v "sh"

printf "check Nginx whether to enable startup\n"
systemctl is-enabled nginx.service

mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.bak

cat >/usr/local/nginx/conf/nginx.conf<<EOF
user  www www;
worker_processes  auto;
worker_rlimit_nofile  65535;

error_log  /var/log/nginx/error.log;
pid        /var/run/nginx.pid;

events {
	use  epoll;
	worker_connections  65535;
	multi_accept  on;
}

http {
	include       mime.types;
	default_type  application/octet-stream;
	charset       utf-8;

	log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
					  '\$status \$body_bytes_sent "\$http_referer" '
					  '"\$http_user_agent" "\$http_x_forwarded_for"';
	
	#access_log  /www/logs/nginx/access.log  main;
	#error_log  /www/logs/nginx/error.log  crit;

	access_log off;	
	error_log  /www/logs/nginx/error.log  warn;

	sendfile       on;
	tcp_nopush     on;	
	tcp_nodelay    on;
	server_tokens  off;
	
	keepalive_timeout  30;
	client_header_timeout  10;
	client_body_timeout  30;
	reset_timedout_connection  on;
	send_timeout  30;
	
	server_names_hash_bucket_size 128; 
	client_header_buffer_size 8k;	
	large_client_header_buffers 8 4k;
	client_max_body_size 8m;

	gzip  on;
	gzip_disable  "msie6";
	gzip_min_length  1k;	
	gzip_comp_level 2;
	gzip_proxied  any;
	gzip_buffers  4  16k; 
	gzip_http_version  1.1;	
	gzip_types  text/plain text/css text/javascript application/x-javascript;
	gzip_vary  on;

	open_file_cache  max=65535  inactive=20s;
	open_file_cache_valid  30s;
	open_file_cache_min_uses  2;
	open_file_cache_errors  on;

	fastcgi_connect_timeout 300;
	fastcgi_send_timeout 300;
	fastcgi_read_timeout 300;
	fastcgi_buffer_size 256k;
	fastcgi_buffers 8 256k;
	fastcgi_busy_buffers_size 256k;
	fastcgi_temp_file_write_size 2048k;

	server {
		listen 80;
		server_name localhost;
		index  index.html index.php;
		root   /www/htdocs/default;

		location ~ \.php\$ {
			fastcgi_pass  127.0.0.1:9000;
			fastcgi_index  index.php;
			include  fastcgi.conf;
		}

		location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)\$ {
			expires 30d; 
		} 
		location ~ .*\.(js|css)?\$ {
			expires 1h; 
		}
		location ~ .*\.html\$ {
			expires 24h; 
		}

		#error_page  403  /errors/403.html;
		#error_page  404  /errors/404.html;
		#error_page  500  /errors/500.html;
		#error_page  502  /errors/502.html;
		#error_page  503  /errors/502.html;
		#error_page  504  /errors/504.html;

		#access_log  /www/logs/nginx/mydomain_access.log  main buffer=16k;
		#error_log  /www/logs/nginx/mydomain_error.log  warn;
	}
	
	#VirtualHost
	#include /usr/local/nginx/domains/*.conf;
}
EOF

#更改Nginx配置文件线程数
cat /proc/cpuinfo | grep "cpu cores" | wc -l
read -p "Input CPU Cores Nums :" coreNum
sed -i "s/^worker_processes  auto;/worker_processes  $coreNum;/g" /usr/local/nginx/conf/nginx.conf
cat /usr/local/nginx/conf/nginx.conf | grep worker_processes

/usr/local/nginx/sbin/nginx -t -c /usr/local/nginx/conf/nginx.conf

read -p "Do you want to restart Nginx?[y/n]:" isrestart
if [ "$isrestart" == "y" ] || [ "$isrestart" == "Y" ]; then
	systemctl restart nginx.service
fi

systemctl status nginx.service

printf "\n========== $softwareName install end =============\n\n"

printf "============== The End. ==============\n"