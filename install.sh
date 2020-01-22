#!/usr/bin/env bash

# Use Git so that we can easy switch between WordPress versions.
if [ ! -d "./wordpress" ]
then
    git clone git@github.com:WordPress/WordPress.git
else
    echo "Found WordPress directory in current folder. Skipping download.\n"
fi

# Clone WooCommerce.
if [ ! -d "./plugins/woocommerce" ]
then
    git clone git@github.com:woocommerce/woocommerce.git plugins
else
    echo "Found WooCommerce directory in current folder. Skipping download.\n"
fi

docker-compose up -d --build && docker-compose exec w.test nginx -s reload
