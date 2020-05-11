FROM ubuntu:19.10

# Bypass tzdata readline mode
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update 
RUN apt-get install -y software-properties-common
RUN apt-get install -y locales curl git && locale-gen en_US.UTF-8
RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php && apt-get -y update
RUN LC_ALL=en_US.UTF-8

# Install PHP7.3-FPM
RUN apt-get install -y wget pkg-config cmake git checkinstall \
                php7.3-bcmath php7.3-bz2 php7.3-cli php7.3-common php7.3-curl \
                php7.3-cgi php7.3-dev php7.3-fpm php7.3-gd php7.3-gmp php7.3-imap php7.3-intl \
                php7.3-json php7.3-ldap php7.3-mbstring php7.3-mysql \
                php7.3-odbc php7.3-opcache php7.3-pgsql php7.3-phpdbg php7.3-pspell \
                php7.3-readline php7.3-recode php7.3-soap php7.3-sqlite3 \
                php7.3-tidy php7.3-xml php7.3-xmlrpc php7.3-xsl php7.3-zip \
                php-tideways php-mongodb php-imagick php-xdebug checkinstall

RUN sed -i "s/;date.timezone =.*/date.timezone = Asia\/Taipei/" /etc/php/7.3/cli/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = Asia\/Taipei/" /etc/php/7.3/fpm/php.ini
RUN sed -i "s/display_errors = Off/display_errors = On/" /etc/php/7.3/fpm/php.ini
RUN sed -i "s/upload_max_filesize = .*/upload_max_filesize = 10M/" /etc/php/7.3/fpm/php.ini
RUN sed -i "s/post_max_size = .*/post_max_size = 12M/" /etc/php/7.3/fpm/php.ini
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.3/fpm/php.ini

RUN sed -i -e "s/pid =.*/pid = \/var\/run\/php7.3-fpm.pid/" /etc/php/7.3/fpm/php-fpm.conf
RUN sed -i -e "s/error_log =.*/error_log = \/proc\/self\/fd\/2/" /etc/php/7.3/fpm/php-fpm.conf
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.3/fpm/php-fpm.conf
RUN sed -i "s/listen = .*/listen = 9000/" /etc/php/7.3/fpm/pool.d/www.conf
RUN sed -i "s/;catch_workers_output = .*/catch_workers_output = yes/" /etc/php/7.3/fpm/pool.d/www.conf

# Install Composer
RUN curl https://getcomposer.org/installer > composer-setup.php && php composer-setup.php && mv composer.phar /usr/local/bin/composer && rm composer-setup.php

# Install php opencv extension
RUN wget https://raw.githubusercontent.com/php-opencv/php-opencv-packages/master/opencv_4.0.1_amd64.deb && dpkg -i opencv_4.0.1_amd64.deb && rm opencv_4.0.1_amd64.deb
RUN git clone https://github.com/php-opencv/php-opencv.git
RUN cd php-opencv && phpize && ./configure --with-php-config=/usr/bin/php-config && make
## build deb package:
RUN cd php-opencv && checkinstall --default --type debian --install=no --pkgname php-opencv --pkgversion "7.2-4.0.1" --pkglicense "Apache 2.0" --pakdir ~ --maintainer "php-opencv" --addso --autodoinst make install && make test
RUN echo "extension=opencv.so" > /etc/php/7.3/fpm/conf.d/opencv.ini
RUN echo "extension=opencv.so" > /etc/php/7.3/cli/conf.d/opencv.ini

# Clean Up
RUN apt-get clean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 9000 => fpm
# 9001 => php-xdebug
EXPOSE 9000 9001

CMD ["php-fpm7.3"]