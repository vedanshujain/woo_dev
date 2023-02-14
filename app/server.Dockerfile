FROM php:7.4-fpm as base_server

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
		libzip-dev\
	; \
	\
	docker-php-ext-configure gd; \
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

# Install nginx.
RUN apt-get install nginx -y

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar
RUN mv wp-cli.phar /usr/local/bin/wp
RUN apt-get install less -y

## Install MailCatcher.
RUN echo 'deb http://ftp.us.debian.org/debian buster main\n' >> /etc/apt/sources.list
RUN apt-get update && apt-get upgrade -y
RUN cat /etc/apt/sources.list
RUN apt-get install unzip -y
RUN apt-get install unzip build-essential libsqlite3-dev ruby-dev -y --fix-missing
RUN gem install mailcatcher --no-document
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -yq install msmtp
RUN sed -i -e "s|;sendmail_path =|sendmail_path = /usr/bin/msmtp -C /etc/msmtprc -t |" /usr/local/etc/php/php.ini-development
RUN sed -i -e "s/smtp_port = 25/smtp_port = 1025/" /usr/local/etc/php/php.ini-development
RUN cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini
RUN touch /var/log/msmtp.log

# Utils
RUN apt-get update && apt-get upgrade -y
RUN apt-get install vim subversion git -y

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php --filename=composer --install-dir=/usr/bin
RUN php -r "unlink('composer-setup.php');"

# Install DB client
RUN apt-get update && apt-get install -y mariadb-client

# Create content directories
RUN mkdir -p /usr/src/public_html/wp-content/
RUN mkdir -p /usr/src/public_html/wordpress
RUN chown -R www-data /usr/src/public_html

# Install and configure SSL
COPY woo.ssl.conf /var/woo.ssl.conf
RUN cd ~ && openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout woo.key -out woo.crt -config /var/woo.ssl.conf
RUN cp ~/woo.crt /etc/ssl/certs/woo.crt
RUN cp ~/woo.key /etc/ssl/private/woo.key

# -------------------------------------------------------------------------- #
FROM base_server as main_server

# Copy configs. This should be towards the end so that we don't need to build entire image if we change configs.
COPY nginx.conf /etc/nginx/sites-enabled/default
COPY php-fpm.conf /usr/local/etc/php-fpm.d/zz-www.conf
COPY wp-config.php /usr/src/wp-config.php
COPY server-start.sh /usr/src/server-start.sh
COPY wp-cli.yml /usr/src/public_html/wp-cli.yml
COPY smtp.conf /etc/msmtprc
WORKDIR /usr/src/public_html/wp-content/plugins/woocommerce

# -------------------------------------------------------------------------- #


# -------------------------------------------------------------------------- #
FROM base_server as debug_server

RUN echo "zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20170718/xdebug.so" >> /usr/local/etc/php/php.ini
RUN pecl install xdebug-3.1.5; \
    docker-php-ext-enable xdebug;

RUN echo "error_reporting = E_ALL" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    echo "display_startup_errors = On" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    echo "display_errors = On" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    echo "memory_limit=-1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    echo "xdebug.remote_enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    echo "xdebug.profiler_enable=0;" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    echo "xdebug.profiler_enable_trigger=1;" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    echo 'xdebug.profiler_output_dir=/usr/src/profiling_data' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    echo 'xdebug.mode=debug' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    echo 'xdebug.start_with_request=yes' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini;

# Copy configs. This should be towards the end so that we don't need to build entire image if we change configs.
COPY debug-server/nginx.conf /etc/nginx/sites-enabled/default
COPY php-fpm.conf /usr/local/etc/php-fpm.d/zz-www.conf
COPY wp-config.php /usr/src/wp-config.php
COPY server-start.sh /usr/src/server-start.sh
COPY wp-cli.yml /usr/src/public_html/wp-cli.yml
COPY smtp.conf /etc/msmtprc
EXPOSE 443
WORKDIR /usr/src/public_html/wp-content/plugins/woocommerce

# -------------------------------------------------------------------------- #


WORKDIR /usr/src/public_html/wp-content/plugins/woocommerce
