#!/usr/bin/bash

MAX_INIT_TIMEOUT_SECONDS=${MAX_INIT_TIMEOUT_SECONDS:-120}

for ((i=1;i<=MAX_INIT_TIMEOUT_SECONDS;i++)); do
    if bundle exec rake --trace db:debug db:migrate ssg:check_synced; then
        exit 0
    else
        sleep 1
    fi
done

exit 1
