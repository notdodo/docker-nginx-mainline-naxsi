FROM alpine:latest
LABEL version 1.2.1
LABEL description "NGINX Mainline version with NAXSI WAF"
MAINTAINER Edoardo Rosa <edoardo [dot] rosa90 [at] gmail [dot] com> (edoz90)

# == BASIC SOFTWARE ============================================================

RUN apk update && apk upgrade

# == ENV / PARAMS ==============================================================

ENV USR_USER http

# == USER / GROUP ==============================================================

RUN adduser -D -u 1000 -h /usr/share/nginx/ -g '${USR_USER}' ${USR_USER}

# == DEPENDENCIES ==============================================================

RUN apk --no-cache --update add \
        libressl-dev    \
        ca-certificates \
        linux-headers   \
        wget            \
        pcre-dev        \
        pcre            \
        zlib-dev        \
        geoip-dev       \
        build-base      \
        autoconf        \
        libtool         \
        geoip           \
        gnupg

# == APP =======================================================================

# Install nginx-mainline

USER ${USR_USER}

ENV NGINX_MAJOR 1
ENV NGINX_MINOR 17
ENV NGINX_BUILD 3
ENV NGINX_VERSION ${NGINX_MAJOR}.${NGINX_MINOR}.${NGINX_BUILD}
ENV NGINX_SOURCE https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
ENV NGINX_PUBKEY https://nginx.org/keys/mdounin.key

ENV NAXSI_VERSION 0.56
ENV NAXSI_SOURCE https://github.com/nbs-system/naxsi/archive/${NAXSI_VERSION}/naxsi-${NAXSI_VERSION}.tar.gz

RUN mkdir -p /usr/share/nginx/sources
WORKDIR /usr/share/nginx/sources

RUN mkdir -p nginx-${NGINX_VERSION}
RUN wget ${NGINX_SOURCE} && wget ${NGINX_SOURCE}.asc && wget ${NGINX_PUBKEY}
RUN gpg --import $(basename ${NGINX_PUBKEY}) && gpg --verify nginx-${NGINX_VERSION}.tar.gz.asc
RUN tar -zxf nginx-${NGINX_VERSION}.tar.gz && \
    rm nginx-${NGINX_VERSION}.tar.gz.asc && \
    rm nginx-${NGINX_VERSION}.tar.gz

RUN wget ${NAXSI_SOURCE} && \
    tar -zxf naxsi-${NAXSI_VERSION}.tar.gz && \
    rm naxsi-${NAXSI_VERSION}.tar.gz

RUN cd nginx-${NGINX_VERSION} && \
    ./configure \
        --prefix=/etc/nginx                              \
        --conf-path=/etc/nginx/nginx.conf                \
        --sbin-path=/usr/bin/nginx                       \
        --pid-path=/run/nginx.pid                        \
        --lock-path=/run/lock/nginx.lock                 \
        --user=${USR_USER}                               \
        --group=${USR_USER}                              \
        --http-log-path=/var/log/nginx/access.log        \
        --error-log-path=stderr                          \
        # Enable support for dynamic modules
        # --with-compat                                   \
        # Enable support for async IO
        --with-file-aio                                  \
        # Enable support for thread execution
        --with-threads                                   \
        # http_addition_module module is a filter that adds text before and after a response.
        --with-http_addition_module                      \
        # The ngx_http_auth_request_module module (1.5.4+) implements client authorization based on the result of a subrequest.
        --with-http_auth_request_module                  \
        # The ngx_http_dav_module module is intended for file management automation via the WebDAV protocol.
        #--with-http_dav_module                           \
        # The ngx_http_flv_module module provides pseudo-streaming server-side support for Flash Video (FLV) files.
        #--with-http_flv_module                           \
        # Allow to return 204 or 444 code for some locations on low memory condition.
        --with-http_degradation_module                   \
        # The ngx_http_geoip_module module (0.8.6+) creates variables with values depending on the client IP address, using the precompiled MaxMind databases.
        --with-http_geoip_module                         \
        # The ngx_http_gunzip_module module is a filter that decompresses responses with “Content-Encoding: gzip” for clients that do not support “gzip” encoding method.
        --with-http_gunzip_module                        \
# The ngx_http_random_index_module module processes requests ending with the slash character (‘/’) and picks a random file in a directory to serve as an index file. The module is processed before the ngx_http_index_module module.
        #--with-http_random_index_module                  \
        # The ngx_http_gzip_static_module module allows sending precompressed files with the “.gz” filename extension instead of regular files.
        #--with-http_gzip_static_module                   \ 
        # The ngx_http_image_filter_module module (0.7.54+) is a filter that transforms images in JPEG, GIF, PNG, and WebP formats.
        #--with-http_image_filter_module                  \
        # The ngx_http_mp4_module module provides pseudo-streaming server-side support for MP4 files. Such files typically have the .mp4, .m4v, or .m4a filename extensions.
        #--with-http_mp4_module                           \
        # The ngx_http_perl_module module is used to implement location and variable handlers in Perl and insert Perl calls into SSI.
        #--with-http_perl_module                          \ 
        # The ngx_http_realip_module module is used to change the client address and optional port to those sent in the specified header field.
        #--with-http_realip_module                        \
        # The ngx_http_secure_link_module module (0.7.18) is used to check authenticity of requested links, protect resources from unauthorized access, and limit link lifetime.
        --with-http_secure_link_module                   \
        # The ngx_http_slice_module module (1.9.8) is a filter that splits a request into subrequests, each returning a certain range of response. The filter provides more effective caching of big responses.
        --with-http_slice_module                         \
        # The ngx_http_ssl_module module provides the necessary support for HTTPS.
        --with-http_ssl_module                           \
        --with-http_stub_status_module                   \
        # The ngx_http_sub_module module is a filter that modifies a response by replacing one specified string by another.
        #--with-http_sub_module                           \
        # The ngx_http_v2_module module (1.9.5) provides support for HTTP/2 and supersedes the ngx_http_spdy_module module.
        --with-http_v2_module                            \
        # The ngx_pcre_jit module enables "just-in-time compilation" (PCRE JIT) for the regular expressions known by the time of configuration parsing.
        --with-pcre-jit                                  \
        # The ngx_mail modules enables the configuration for mail servers
        #--with-mail                                      \
        # The ngx_mail_ssl_module module provides the necessary support for a mail proxy server to work with the SSL/TLS protocol.
        #--with-mail_ssl_module                           \ 
        # the ngx_stream_core_module enables use of upstream o stream server
        #--with-stream                                    \
        # The ngx_stream_geoip_module module (1.11.3) creates variables with values depending on the client IP address, using the precompiled MaxMind databases.
        #--with-stream_geoip_module                       \
        # The ngx_stream_realip_module module is used to change the client address and port to the ones sent in the PROXY protocol header (1.11.4).
        #--with-stream_realip_module                      \
        # The ngx_stream_ssl_module module (1.9.0) provides the necessary support for a stream proxy server to work with the SSL/TLS protocol.
        #--with-stream_ssl_module                         \
        # The ngx_stream_ssl_preread_module module (1.11.5) allows extracting information from the ClientHello message without terminating SSL/TLS
        #--with-stream_ssl_preread_module                 \
        # Modules                                        \
        --add-module=../naxsi-${NAXSI_VERSION}/naxsi_src \
        && make -j2 

# Change the user back to 'root'.
USER root

RUN cd nginx-${NGINX_VERSION} && \
    make install && \
    mkdir /etc/nginx/conf.d && \
    mkdir /etc/nginx/sites-enabled && \
    mkdir -p /usr/share/nginx/html/ && \
    install -m644 html/index.html /usr/share/nginx/html/ && \
    install -m644 html/50x.html /usr/share/nginx/html/ && \
    rm /etc/nginx/*.default && \
    install -Dm644 ../naxsi-${NAXSI_VERSION}/naxsi_config/naxsi_core.rules /etc/nginx/naxsi_core.rules

WORKDIR /usr/share/nginx

# Copy configurations
ADD dist/nginx.conf /etc/nginx/nginx.conf
ADD dist/conf.d/default.conf /etc/nginx/conf.d/default
ADD dist/conf.d/badbot.conf /etc/nginx/conf.d/badbot.conf
ADD dist/sites /etc/nginx/sites-enabled/

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

RUN apk add --update --no-cache vim bash-completion tmux nginx-vim
    
# == CLEAN ================================================================

RUN apk del \
        libressl-dev    \
        linux-headers   \
        wget            \
        pcre-dev        \
        zlib-dev        \
        geoip-dev       \
        build-base      \
        autoconf        \
        libtool         \
        gnupg

RUN rm -r /usr/share/nginx/sources 

# == ENTRYPOINT ================================================================

EXPOSE 80
EXPOSE 443

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
