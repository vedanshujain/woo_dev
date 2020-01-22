FROM mysql:5.7

COPY slow_query.sh /usr/src/slow_query.sh

# Set default password
ENV MYSQL_ROOT_PASSWORD=mysql
ENV MYSQL_DATABASE=woo_dev

EXPOSE 3306
