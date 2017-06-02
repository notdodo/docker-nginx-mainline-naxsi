FROM alpine:3.6

MAINTAINER Edoardo Rosa <edoardo [dot] rosa90 [at] gmail [dot] com> (edoz90)

# == BASIC SOFTWARE ============================================================

RUN apk update \
 && apk upgrade

RUN apk add --update openssl-dev zlib-dev build-base bash wget

# == ENV / PARAMS ==============================================================

ENV USER http
ENV HOME /home/${USER}

# == USER / GROUP ==============================================================
RUN addgroup -S ${USER}
RUN adduser -D ${USER} -h ${HOME} -s /bin/nologin -G http http

# == DEPENDENCIES ==============================================================

RUN apk add --update gnupg \
                     geoip-dev \
                     pcre-dev \
                     wget \
                     ca-certificates \
                     linux-headers \
                     file \
                     certbot \
                     vim

# == APP =======================================================================

# Install the application as the unpriviliged user.
USER http

ENV NGINX_MAJOR 1
ENV NGINX_MINOR 13
ENV NGINX_BUILD 1
ENV NGINX_VERSION ${NGINX_MAJOR}.${NGINX_MINOR}.${NGINX_BUILD}
ENV NGINX_SOURCE https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
ENV NGINX_PUBKEY B0F4253373F8F6F510D42178520A9993A1C052F8
ENV NGINX_SRC ${HOME}/sources/nginx-${NGINX_VERSION}

ENV NAXSI_VERSION 0.55.3
ENV NAXSI_SOURCE https://github.com/nbs-system/naxsi/archive/${NAXSI_VERSION}/naxsi-${NAXSI_VERSION}.tar.gz

RUN mkdir -p ${HOME}/sources && mkdir -p ${NGINX_SRC}
RUN cd ${HOME}/sources && \
    wget ${NGINX_SOURCE} && wget ${NGINX_SOURCE}.asc && \
    gpg --keyserver pgpkeys.mit.edu --recv-key ${NGINX_PUBKEY}  && \
    gpg --verify nginx-${NGINX_VERSION}.tar.gz.asc nginx-${NGINX_VERSION}.tar.gz && \
    tar -zxf nginx-${NGINX_VERSION}.tar.gz && \
    rm nginx-${NGINX_VERSION}.tar.gz.asc && \
    rm nginx-${NGINX_VERSION}.tar.gz

RUN cd ${HOME}/sources && \
    wget ${NAXSI_SOURCE} && \
    tar -zxf naxsi-${NAXSI_VERSION}.tar.gz && \
    rm naxsi-${NAXSI_VERSION}.tar.gz

RUN cd ${NGINX_SRC} && \
    ./configure \
        --prefix=/etc/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --sbin-path=/usr/bin/nginx \
        --pid-path=/run/nginx.pid \
        --lock-path=/run/lock/nginx.lock \
        --user=http \
        --group=http \
        --http-log-path=/var/log/nginx/access.log \
        --error-log-path=stderr \
        --with-compat \
        --with-file-aio \
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_dav_module \
        --with-http_degradation_module \
        --with-http_flv_module \
        --with-http_geoip_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \ 
        --with-http_realip_module \
        --with-http_secure_link_module \
        --with-http_slice_module \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_sub_module \
        --with-http_v2_module \
        --with-pcre-jit \
        --with-stream \
        --with-stream_geoip_module \
        --with-stream_realip_module \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --with-threads \
        --add-dynamic-module=../naxsi-${NAXSI_VERSION}/naxsi_src \
        && \
        make 

# Change the user back to `root`.
USER root

RUN cd ${NGINX_BUILD} && \
    make install && \
    mkdir /etc/nginx/conf.d && \
    mkdir /etc/nginx/sites-enabled && \
    mkdir -p /usr/share/nginx/html/ && \
    install -m644 html/index.html /usr/share/nginx/html/ && \
    install -m644 html/50x.html /usr/share/nginx/html/ && \
    rm /etc/nginx/*.default && \
    for mod in objs/*.so; do \
		install -Dm755 $mod /usr/lib/nginx/modules/$mod; \
	done && \
    install -Dm644 ../naxsi-${NAXSI_VERSION}/naxsi_config/naxsi_core.rules /etc/nginx/naxsi_core.rules && \
    for i in indent syntax; do \
        cp contrib/vim/${i}/nginx.vim /usr/share/vim/vim80/${i}/nginx.vim; \
    done

# Copy configuration
ADD dist/nginx.conf /etc/nginx/nginx.conf
ADD dist/conf.d/default.conf /etc/nginx/conf.d/default
ADD dist/conf.d/badbot.conf /etc/nginx/conf.d/badbot.conf
ADD dist/sites /etc/nginx/sites-enabled/

# Clean
RUN rm ${HOME}/*

# == LOGROTATE =================================================================

RUN apk add --update --no-cache logrotate

RUN mv /etc/periodic/daily/logrotate /etc/periodic/hourly/logrotate

# Add MYAPP-specific logrotate configuration.
ADD dist/logrotate.conf /etc/logrotate.d/nginx

# == RSYSLOG ===================================================================

RUN apk add --update --no-cache rsyslog
ADD dist/rsyslog.conf /etc/rsyslog.d/90.nginx.conf
 
# == SUPERVISORD ===============================================================

RUN apk add --update --no-cache supervisor

ADD dist/supervisord.ini /etc/supervisor.d/supervisord.ini

# == TOOLS (useful when inspecting the container) ==============================

RUN apk add --update --no-cache vim bash-completion tmux
    
# == ENTRYPOINT ================================================================

EXPOSE 80
EXPOSE 443

#CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
CMD ["nginx"]
