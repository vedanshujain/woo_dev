#!/usr/bin/env bash

## Extra commands while starting up.

cp /usr/src/wp-config.php /usr/src/public_html/wordpress/wp-config.php
nginx && mailcatcher --http-ip 0.0.0.0 && php-fpm
