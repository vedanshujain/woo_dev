#!/usr/bin/env bash
docker-compose logs -f --tail=100 w.db w.test d.w.test | grep "\[.*\]s"
