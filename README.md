# Customer CI/CD Multi-Environment Docker Project

Implements Git -> Jenkins -> Docker -> DEV/UAT/PRODUCTION with isolated Docker networks, PostgreSQL containers, named volumes, validation and rollback.

| Environment | Branch | App | Port | Network | DB | Volume |
|---|---|---|---:|---|---|---|
| DEV | develop | customer-app-dev | 8081 | customer-dev-net | customer-db-dev | customer-db-dev-data |
| UAT | release | customer-app-uat | 8082 | customer-uat-net | customer-db-uat | customer-db-uat-data |
| PRODUCTION | main | customer-app-prod | 8083 | customer-prod-net | customer-db-prod | customer-db-prod-data |

## Prerequisites
- Docker Engine + Docker Compose
- Git
- Jenkins with Docker access
- curl
- Jenkins credentials: `git-credentials`, `customer-db-password`

## Quick DEV test
```bash
docker build -t customer-app:1.0 ./app
docker compose -f deploy/compose.dev.yml up -d
curl http://localhost:8081/health
curl http://localhost:8081/db
curl http://localhost:8081/version
```

Replace `YOUR-GIT-REPOSITORY` in `Jenkinsfile` with your repository URL.
