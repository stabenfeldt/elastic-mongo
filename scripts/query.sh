#!/bin/bash
set -e
# Any subsequent(*) commands which fail will cause the shell script to exit immediately

MONGODB1=`ping -c 1 mongo1 | head -1  | cut -d "(" -f 2 | cut -d ")" -f 1`
MONGODB2=`ping -c 1 mongo2 | head -1  | cut -d "(" -f 2 | cut -d ")" -f 1`
MONGODB3=`ping -c 1 mongo3 | head -1  | cut -d "(" -f 2 | cut -d ")" -f 1`
ES=`ping -c 1 elasticsearch | head -1  | cut -d "(" -f 2 | cut -d ")" -f 1`


/scripts/wait-until-mongodb-started.sh


################################
# Write to MongoDB

echo "================================="
echo "Writing to MongoDB"
mongo --quiet ${MONGODB1}:27017/harvester-test --eval '
  rs.config();
  db.entries.insertOne({title: "Breaking news", content: "It\"s not summer yet."});
'


echo "================================="
echo "Fetching data from Mongo"
mongo --quiet ${MONGODB1}:27017/harvester-test --eval '
  printjson(db.entries.find().limit(10).toArray());
'
echo "================================="


################################
# Read from Elasticsearch

printf "\nWaiting for the transporter to start\n\n"

until test -f /scripts/TRANSPORTER-STARTED; do
  printf '.'
  sleep 1
done
printf "\nTransporter started \n\n"

printf "\nReading from Elasticsearch\n\n"
curl -XGET "http://elasticsearch:9200/_search?pretty&q=*:*"


echo "================================="
echo "DONE"
