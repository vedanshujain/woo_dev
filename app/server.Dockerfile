FROM php:7.2-fpm

# ----- Start section copied from https://github.com/docker-library/wordpress/blob/master/php7.2/fpm/Dockerfile ----- #

# install the PHP extensions we need
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libjpeg-dev \
		libpng-dev \
	; \
	\
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install gd mysqli opcache zip; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini
# https://codex.wordpress.org/Editing_wp-config.php#Configure_Error_Logging
RUN { \
		echo 'error_reporting = 4339'; \
		echo 'display_errors = ON'; \
		echo 'display_startup_errors = ON'; \
		echo 'log_errors = On'; \
		echo 'error_log = /dev/stderr'; \
		echo 'log_errors_max_len = 1024'; \
		echo 'ignore_repeated_errors = On'; \
		echo 'ignore_repeated_source = Off'; \
		echo 'html_errors = Off'; \
	} > /usr/local/etc/php/conf.d/error-logging.ini

# ----- Copied section ends ----- #

RUN apt-get update

# Install and configure nginx
RUN apt-get install nginx -y
COPY nginx.conf /etc/nginx/sites-enabled/woo.conf
COPY php-fpm.conf /usr/local/etc/php-fpm.d/zz-www.conf

# Install and configure SSL
COPY woo.ssl.conf /var/woo.ssl.conf
RUN cd ~ && openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout woo.key -out woo.crt -config /var/woo.ssl.conf
RUN cp ~/woo.crt /etc/ssl/certs/woo.crt
RUN cp ~/woo.key /etc/ssl/private/woo.key

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar
RUN mv wp-cli.phar /usr/local/bin/wp
RUN apt-get install less -y
COPY wp-cli.yml /usr/src/public_html/wp-cli.yml

## Install MailCatcher.
RUN echo 'deb http://ftp.us.debian.org/debian buster main\n' >> /etc/apt/sources.list
RUN apt-get update && apt-get upgrade -y
RUN cat /etc/apt/sources.list
RUN apt-get install unzip -y
RUN apt-get install unzip build-essential libsqlite3-dev ruby-dev -y --fix-missing
RUN gem install mailcatcher --no-ri --no-rdoc
COPY smtp.conf /etc/msmtprc
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -yq install msmtp
RUN sed -i -e "s|;sendmail_path =|sendmail_path = /usr/bin/msmtp -C /etc/msmtprc -t |" /usr/local/etc/php/php.ini-development
RUN sed -i -e "s/smtp_port = 25/smtp_port = 1025/" /usr/local/etc/php/php.ini-development
RUN cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini
RUN touch /var/log/msmtp.log

# Utils
RUN apt-get update && apt-get upgrade -y
RUN apt-get install vim subversion git -y

# Replace nginx default conf because it conflicts with woo.conf
RUN mv /etc/nginx/sites-enabled/woo.conf /etc/nginx/sites-enabled/default

RUN mkdir /usr/src/public_html/wp-content/
RUN mkdir /usr/src/public_html/wordpress
WORKDIR /usr/src/public_html
