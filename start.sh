#!/usr/bin/env bash
docker-compose up -d && docker-compose exec w.test nginx -s reload
