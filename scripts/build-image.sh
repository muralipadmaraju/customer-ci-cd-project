#!/usr/bin/env bash
set -e
VERSION="${1:-1.0}"
docker build -t "customer-app:${VERSION}" ./app
docker images customer-app
