# Troubleshooting scenarios

The assessment requires at least four failures. Demonstrate and then fix these controlled failures:

1. Wrong Git branch — DEV must use `develop`.
2. Invalid image tag — request a tag that was not built.
3. Port already allocated — inspect `docker ps`, stop the conflicting container, retry.
4. Wrong DB hostname — do not use `localhost`; use `customer-db-dev` / the environment DB name.
5. Different Docker networks — app and DB must share the environment network.
6. Missing environment variable — restore DB_HOST/DB credentials.
7. No DB volume — recreate using the required named volume.
8. Health endpoint failure — Jenkins must fail validation rather than report success.

Useful commands:

`docker ps`

`docker network inspect customer-dev-net`

`docker volume inspect customer-db-dev-data`

`curl -f http://localhost:8081/health`

`curl -f http://localhost:8081/db`
