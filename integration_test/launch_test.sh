#!/bin/bash

# MP="`dirname \"$0\"`"
# MP="`( cd \"$MP\" && pwd )`"
# cd $MP

args="$@"

# Get local IP and set .env
ip_address=$(hostname -I | awk '{print $1}')
echo "ip_address=$ip_address" > .env

## Start local Duniter node
cd integration_test/duniter
docker-compose down
rm -rf data/chains
docker-compose up -d
cd ../..

# Start integration test
flutter test integration_test/app_test.dart

# Stop Duniter
cd integration_test/duniter
docker-compose down


