FROM debian:bullseye

# Configurar los repositorios para Debian 11 (Bullseye)
RUN echo "deb http://deb.debian.org/debian bullseye main contrib non-free" > /etc/apt/sources.list
RUN echo "deb http://deb.debian.org/debian bullseye-updates main contrib non-free" > /etc/apt/sources.list.d/bullseye-updates.list
RUN echo "deb http://security.debian.org/debian-security bullseye-security main contrib non-free" > /etc/apt/sources.list.d/debian-security.list
RUN echo "deb http://deb.debian.org/debian bullseye-backports main contrib non-free" > /etc/apt/sources.list.d/bullseye-backports.list

# Build ruby from source
RUN apt-get -o Acquire::Check-Valid-Until=false update -q && apt-get -y install \
    build-essential \
    bison \
    openssl \
#    libreadline7 \
    libreadline8 \
    libreadline-dev \
    libyaml-dev \
    libxml2-dev \
    libxslt-dev \
    zlib1g \
    zlib1g-dev \
    libssl-dev \
    autoconf \
    libc6-dev \
    ncurses-dev \
    libaprutil1-dev \
    libffi-dev \
    libcurl4-openssl-dev \
    libapr1-dev \
    wget \
    supervisor
    #&& cd ~ \
    #&& wget https://cache.ruby-lang.org/pub/ruby/2.4/ruby-2.4.5.tar.gz \
    #&& tar -xvf ruby-2.4.5.tar.gz \
    #&& cd ruby-2.4.5/ \
    #&& ./configure \
    #&& make \
    #&& make test \
    #&& make install \
    #&& cd ~ \
    #&& rm -rf ruby-2.4.5 \
    #&& apt-get -y upgrade

# Configure sury
RUN apt-get -y install lsb-release apt-transport-https ca-certificates  \
    && wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add - \
    && echo "deb https://packages.sury.org/php/ bullseye main" | tee /etc/apt/sources.list.d/php.list

# Install php and other requirements.
RUN apt-get -o Acquire::Check-Valid-Until=false update -q \
    && apt-get -y install \
    bash \
    curl \
    mailutils \
    default-mysql-client \
    nginx \
    php-pear \
    php7.4-cli \
    php7.4-common \
    php7.4-curl \
    php7.4-dev \
    php7.4-fpm \
    php7.4-gd \
    php7.4-imap \
    php7.4-memcache \
    php7.4-mysqlnd \
    php7.4-xml \
    php7.4-xmlrpc \
    python-setuptools \
    ruby-dev \
    && apt-get -y autoremove \
    && apt-get clean

# Forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

# Configure php
ADD deployment/php/php.ini /etc/php/7.4/fpm/php.ini
ADD deployment/php/uploads.ini /etc/php/7.4/fpm/conf.d/
ADD deployment/php/php-fpm.conf /etc/php/7.4/fpm/php-fpm.conf
RUN phpenmod opcache && \
    phpenmod mysqlnd && \
    /etc/init.d/php7.4-fpm start -t -c /etc/php/7.4/fpm/php-fpm.conf

RUN mkdir -p /var/lib/php/7.4/sessions && \
    chown www-data:www-data /var/lib/php/7.4/sessions

# Add supervisor
ADD ./deployment/supervisord.conf /etc/supervisord.conf

# Install css compiler
RUN gem install sass

# Cleanup
RUN apt-get -y remove \
    automake \
    build-essential \
    git \
    ruby-dev \
    && apt-get -y autoremove \
    && apt-get clean

# Copy over the nginx configs
RUN rm /etc/nginx/sites-enabled/*
ADD deployment/nginx/conf.d /etc/nginx/conf.d
ADD deployment/nginx/includes /etc/nginx/includes
ADD deployment/nginx/site /etc/nginx/sites-enabled
ADD deployment/nginx/nginx.conf /etc/nginx/nginx.conf
RUN nginx -t

# Default to production
ENV ENV=production

# Seeds
ADD deployment /deployment

# Startup
ADD deployment/start.sh /usr/local/bin/start.sh
ADD deployment/build-css.sh /usr/local/bin/build-css.sh


RUN chmod +x /usr/local/bin/start.sh

CMD ["/usr/local/bin/start.sh"]

# Workdir
RUN mkdir -p /var/www/html
WORKDIR /var/www/html

# Application
ADD wordpress /var/www/html/

RUN chmod +x /usr/local/bin/build-css.sh

# Compile css
RUN /usr/local/bin/build-css.sh

# Copy over git information
RUN mkdir -p /var/www/html/.git
ADD .git/HEAD /var/www/html/.git/HEAD
ADD .git/ORIG_HEAD /var/www/html/.git/ORIG_HEAD
RUN ["/bin/sh", "-c", "cat /var/www/html/.git/HEAD | cut -d'/' -f 3 > /var/www/html/.git/BRANCH"]
