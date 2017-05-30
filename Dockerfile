FROM linuxserver/letsencrypt
MAINTAINER rix1337

LABEL org.freenas.interactive="false" 					\
      org.freenas.version="1" 						\
      org.freenas.autostart="true" 					\
      org.freenas.privileged="true"					\
      org.freenas.expose-ports-at-host="true" 				\
      org.freenas.port-mappings="80:8080/tcp,443:4343/tcp"		\
      org.freenas.web-ui-protocol="http" 				\
      org.freenas.web-ui-port="80" 					\
      org.freenas.volumes="[						\
          {								\
              \"name\": \"/config\",					\
              \"descr\": \"Config storage space\"			\
          }								\
      ]"								\
      org.freenas.settings="[ 						\
          {								\
              \"env\": \"EMAIL\",					\
              \"descr\": \"email for cert registration\",		\
              \"optional\": false					\
          },								\
          {								\
              \"env\": \"DHLEVEL\",					\
              \"descr\": \"encryption bits 2048/1024/4096\", 		\
              \"optional\": true					\
          },								\
          {								\
              \"env\": \"URL\",						\
              \"descr\": \"your domain name minus http://\",		\
              \"optional\": false					\
          },								\
          {								\
              \"env\": \"SUBDOMAINS\",					\
              \"descr\": \"your subdomains (ie. www,ftp,cloud)\",	\
              \"optional\": true					\
          },								\
          {								\
              \"env\": \"ONLY_SUBDOMAINS\",				\
              \"descr\": \"only get certs for certain subdomains\",	\
              \"optional\": true					\
          },								\
          {								\
              \"env\": \"TZ\",						\
              \"descr\": \"timezone ie. America/New_York\",		\
              \"optional\": true					\
          },								\
          {								\
              \"env\": \"PGID\",					\
              \"descr\": \"GroupID\",					\
              \"optional\": true					\
          },								\
          {								\
              \"env\": \"PUID\",					\
              \"descr\": \"UserID\",					\
              \"optional\": true					\
         }								\
      ]"

# Set latest stable nginx
ENV NGINX_VERSION nginx-1.13.0
ENV HEADERS_MORE_VERSION 0.32

# Install PHP7 and GeoIP Packages for Organizr
RUN \
 apk add --no-cache \
	php7-pdo_sqlite \
	php7-sqlite3 \
	php7-zip \
	geoip-dev
        
# Build nginx with custom modules (geoip/realip/http_sub/headers_more)
RUN apk \ 
        --update add openssl-dev pcre-dev zlib-dev wget build-base && \
    mkdir -p /tmp/src && \
    mkdir -p /tmp/modules && \
    cd /tmp/modules && \
    wget https://github.com/openresty/headers-more-nginx-module/archive/v$HEADERS_MORE_VERSION.tar.gz -O headers-more-$HEADERS_MORE_VERSION.tar.gz && \
    tar xzf headers-more-$HEADERS_MORE_VERSION.tar.gz && \
    cd /tmp/src && \
    wget http://nginx.org/download/${NGINX_VERSION}.tar.gz && \
    tar -zxvf ${NGINX_VERSION}.tar.gz && \
    cd /tmp/src/${NGINX_VERSION} && \
    ./configure \
        --prefix=/var/lib/nginx \ 
        --sbin-path=/usr/sbin/nginx \ 
        --conf-path=/etc/nginx/nginx.conf \ 
        --pid-path=/run/nginx/nginx.pid \ 
        --lock-path=/run/nginx/nginx.lock \ 
        --http-client-body-temp-path=/var/lib/nginx/tmp/client_body \ 
        --http-proxy-temp-path=/var/lib/nginx/tmp/proxy \ 
        --http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi \ 
        --http-uwsgi-temp-path=/var/lib/nginx/tmp/uwsgi \ 
        --http-scgi-temp-path=/var/lib/nginx/tmp/scgi \ 
        --user=nginx \ 
        --group=nginx \ 
        --with-pcre-jit \ 
        --with-http_dav_module \ 
        --with-http_ssl_module \ 
        --with-http_stub_status_module \ 
        --with-http_gzip_static_module \ 
        --with-http_v2_module \ 
	--add-module=/tmp/modules/headers-more-nginx-module-$HEADERS_MORE_VERSION \
        --with-http_auth_request_module \ 
        --with-mail \ 
        --with-mail_ssl_module \ 
	--with-http_geoip_module \ 
	--with-http_realip_module \ 
        --with-http_sub_module && \
    make && \
    make install && \
    apk del build-base && \
    rm -rf /tmp/src && \
    rm -rf /var/cache/apk/*
    
# add local files
COPY root/ /
