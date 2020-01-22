#!/usr/bin/env bash

docker-compose exec w.db sh -c "echo > /var/log/mysql/query.log"

docker-compose exec w.test sh -c "echo > /var/log/nginx/custom.log"
docker-compose exec w.test sh -c "echo > /var/log/nginx/access.log"
docker-compose exec w.test sh -c "echo > /var/log/nginx/error.log"

docker-compose exec d.w.test sh -c "echo > /var/log/nginx/custom.log"
docker-compose exec d.w.test sh -c "echo > /var/log/nginx/access.log"
docker-compose exec d.w.test sh -c "echo > /var/log/nginx/error.log"
