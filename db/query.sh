#!/usr/bin/env bash
tail -f /var/log/mysql/query.log | grep --color=always -e "^" -e "Query_time: .* "
