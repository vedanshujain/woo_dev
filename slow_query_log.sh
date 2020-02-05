#!/usr/bin/env bash
docker-compose exec w.db sh "/usr/src/slow_query.sh"
