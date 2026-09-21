# Command-by-command assessment guide

## Build
`docker build -t customer-app:1.0 ./app` — builds the application image.

`docker images` — verifies the image exists.

## DEV
`docker compose -f deploy/compose.dev.yml up -d` — starts app and DB on the DEV network with a named DB volume.

`docker ps` — verifies containers.

`docker network inspect customer-dev-net` — proves app and DB share the expected network.

`docker volume inspect customer-db-dev-data` — proves persistent DB storage.

`curl http://localhost:8081/health` — application health.

`curl http://localhost:8081/db` — application-to-database connectivity.

`curl http://localhost:8081/version` — requested version/environment.

## Git
`git init`

`git add .`

`git commit -m "initial customer application"`

`git branch -M main`

`git checkout -b develop`

`git checkout -b release`

`git checkout develop`

`git checkout -b feature/customer-search`

Create at least three meaningful feature commits, then merge feature -> develop -> release -> main.

`git log --oneline --graph --all --decorate` — evidence of the Git strategy.

## Jenkins
Replace `YOUR-GIT-REPOSITORY` in `Jenkinsfile`.

Credentials: `git-credentials` and `customer-db-password`.

Parameters: ENVIRONMENT, ACTION, VERSION, RUN_TESTS, PRODUCTION_CONFIRM.

Production requires explicit confirmation.

## Rollback
Deploy 5.1, make DB validation fail, then run a Jenkins rollback with VERSION=5.0 and validate `/health`, `/db`, and `/version`.
