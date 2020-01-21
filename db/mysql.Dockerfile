FROM mysql:5.7

# Set default password
ENV MYSQL_ROOT_PASSWORD=mysql
ENV MYSQL_DATABASE=woo_dev

EXPOSE 3306
