#!/usr/bin/env bash
set -e
docker ps
docker network ls
docker volume ls
curl -f http://localhost:8081/health
curl -f http://localhost:8081/db
curl -f http://localhost:8081/version
curl -f http://localhost:8082/health
curl -f http://localhost:8082/db
curl -f http://localhost:8082/version
curl -f http://localhost:8083/health
curl -f http://localhost:8083/db
curl -f http://localhost:8083/version
echo "ALL VALIDATIONS PASSED"
