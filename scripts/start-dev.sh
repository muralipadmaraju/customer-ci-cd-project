#!/usr/bin/env bash
set -e
VERSION="${1:-1.0}"
docker build -t "customer-app:${VERSION}" ./app
sed "s/customer-app:1.0/customer-app:${VERSION}/g; s/APP_VERSION: \"1.0\"/APP_VERSION: \"${VERSION}\"/g" deploy/compose.dev.yml > /tmp/customer-compose-dev.yml
docker compose -f /tmp/customer-compose-dev.yml up -d
curl -f http://localhost:8081/health
curl -f http://localhost:8081/db
curl -f http://localhost:8081/version
