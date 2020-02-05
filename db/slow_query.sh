#!/usr/bin/env bash
tail -f /var/log/mysql/slow_query.log | grep --color=always -e "^" -e "Query_time: .* "
