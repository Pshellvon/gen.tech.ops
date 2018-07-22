FROM ubuntu:16.04

ENV VER_NGINX=1.15.0

ENV NGINX_ROOT=/nginx
ENV WEB_DIR ${NGINX_ROOT}/html

#Install all required dependecies
RUN apt-get -qq update
RUN apt-get -qq -y install libpcre3 libpcre3-dev zlib1g-dev libssl-dev gcc make wget curl

#Download packages
RUN wget http://nginx.org/download/nginx-${VER_NGINX}.tar.gz

#Untar it
RUN tar -xzvf nginx-${VER_NGINX}.tar.gz && rm nginx-${VER_NGINX}.tar.gz

#Build Nginx with custom options
WORKDIR /nginx-${VER_NGINX}
RUN ./configure --prefix=${NGINX_ROOT} \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module

RUN make install
RUN ln -s ${NGINX_ROOT}/sbin/nginx /usr/local/sbin/nginx

#Options
WORKDIR ${WEB_DIR}
EXPOSE 80

# This is the default CMD used by nginx image
CMD ["nginx", "-g", "daemon off;"]
