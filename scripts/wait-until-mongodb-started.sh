#!/bin/bash

echo "Waiting for the mongos to complete the election."
if command -v mongo >/dev/null 2>&1; then
  until mongo --quiet --host mongo1:27017 --eval 'db.adminCommand({isMaster:1}).ismaster' 2>/dev/null | grep true; do
    printf '.'
    sleep 1
  done
else
  until (exec 3<>/dev/tcp/mongo1/27017) 2>/dev/null; do
    printf '.'
    sleep 1
  done
  exec 3<&-
  exec 3>&-
fi
echo "The primary is elected."

echo "Waiting for Elasticsearch to start."
until curl elasticsearch:9200/_cluster/health?pretty 2>&1 | grep status | egrep "(green|yellow)"; do
  printf '.'
  sleep 1
done
echo "Elasticsearch started."
