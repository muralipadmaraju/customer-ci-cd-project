# Rollback 5.1 -> 5.0

1. Confirm 5.0:
`curl http://localhost:8083/version`
`curl http://localhost:8083/db`

2. Jenkins deploy:
- ENVIRONMENT=PRODUCTION
- ACTION=DEPLOY
- VERSION=5.1
- RUN_TESTS=YES
- PRODUCTION_CONFIRM=true

3. Introduce a controlled bad DB hostname for 5.1 and run:
`curl -f http://localhost:8083/db`

4. The deployment must fail validation.

5. Jenkins rollback:
- ENVIRONMENT=PRODUCTION
- ACTION=ROLLBACK
- VERSION=5.0
- PRODUCTION_CONFIRM=true

6. Validate:
`curl http://localhost:8083/version`
`curl http://localhost:8083/db`
`curl http://localhost:8083/health`
