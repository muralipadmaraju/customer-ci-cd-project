#!/usr/bin/env bash
set -e
docker exec customer-db-dev psql -U customer -d customer -c "CREATE TABLE IF NOT EXISTS test_data (id SERIAL PRIMARY KEY, message TEXT);"
docker exec customer-db-dev psql -U customer -d customer -c "INSERT INTO test_data(message) VALUES ('persistent data');"
docker exec customer-db-dev psql -U customer -d customer -c "SELECT * FROM test_data;"
docker rm -f customer-db-dev
docker run -d --name customer-db-dev --network customer-dev-net -e POSTGRES_DB=customer -e POSTGRES_USER=customer -e POSTGRES_PASSWORD=customer123 -v customer-db-dev-data:/var/lib/postgresql/data postgres:16-alpine
sleep 8
docker exec customer-db-dev psql -U customer -d customer -c "SELECT * FROM test_data;"
