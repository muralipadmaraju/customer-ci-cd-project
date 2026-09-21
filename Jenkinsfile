pipeline {
    agent any

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['DEV', 'UAT', 'PRODUCTION'],
            description: 'Deployment environment'
        )

        choice(
            name: 'ACTION',
            choices: ['DEPLOY', 'ROLLBACK'],
            description: 'Deployment action'
        )

        string(
            name: 'VERSION',
            defaultValue: '1.0',
            description: 'Application version'
        )

        choice(
            name: 'RUN_TESTS',
            choices: ['YES', 'NO'],
            description: 'Run validation tests'
        )

        booleanParam(
            name: 'PRODUCTION_CONFIRMATION',
            defaultValue: false,
            description: 'Required for production deployment'
        )
    }

    environment {
        IMAGE_NAME = 'customer-app'
    }

    stages {

        stage('Resolve Deployment Configuration') {
            steps {
                script {
                    if (params.ENVIRONMENT == 'DEV') {
                        env.BRANCH = 'develop'
                        env.APP_CONTAINER = 'customer-app-dev'
                        env.DB_CONTAINER = 'customer-db-dev'
                        env.NETWORK = 'customer-dev-net'
                        env.PORT = '8081'
                        env.DB_VOLUME = 'customer-db-dev-data'
                    }
                    else if (params.ENVIRONMENT == 'UAT') {
                        env.BRANCH = 'release'
                        env.APP_CONTAINER = 'customer-app-uat'
                        env.DB_CONTAINER = 'customer-db-uat'
                        env.NETWORK = 'customer-uat-net'
                        env.PORT = '8082'
                        env.DB_VOLUME = 'customer-db-uat-data'
                    }
                    else if (params.ENVIRONMENT == 'PRODUCTION') {
                        env.BRANCH = 'main'
                        env.APP_CONTAINER = 'customer-app-prod'
                        env.DB_CONTAINER = 'customer-db-prod'
                        env.NETWORK = 'customer-prod-net'
                        env.PORT = '8083'
                        env.DB_VOLUME = 'customer-db-prod-data'

                        if (!params.PRODUCTION_CONFIRMATION) {
                            error('Production deployment requires explicit confirmation.')
                        }
                    }

                    echo """
                    ========================================
                    RESOLVED DEPLOYMENT CONFIGURATION
                    ========================================
                    Environment : ${params.ENVIRONMENT}
                    Branch      : ${env.BRANCH}
                    Action      : ${params.ACTION}
                    Version     : ${params.VERSION}
                    App         : ${env.APP_CONTAINER}
                    Database    : ${env.DB_CONTAINER}
                    Network     : ${env.NETWORK}
                    Host Port   : ${env.PORT}
                    DB Volume   : ${env.DB_VOLUME}
                    ========================================
                    """
                }
            }
        }

        stage('Checkout') {
            steps {
                git branch: "${env.BRANCH}",
                    url: 'https://github.com/muralipadmaraju/customer-ci-cd-project.git'
            }
        }

        stage('Build Docker Image') {
            when {
                expression {
                    params.ACTION == 'DEPLOY'
                }
            }

            steps {
                bat """
                    docker build -t ${IMAGE_NAME}:${params.VERSION} .
                """
            }
        }

        stage('Prepare Network') {
            when {
                expression {
                    params.ACTION == 'DEPLOY'
                }
            }

            steps {
                bat """
                    docker network inspect ${NETWORK} >nul 2>&1 || docker network create ${NETWORK}
                """
            }
        }

        stage('Deploy Database') {
            when {
                expression {
                    params.ACTION == 'DEPLOY'
                }
            }

            steps {
                bat """
                    docker rm -f ${DB_CONTAINER} >nul 2>&1 || exit /b 0

                    docker volume inspect ${DB_VOLUME} >nul 2>&1 || docker volume create ${DB_VOLUME}

                    docker run -d ^
                      --name ${DB_CONTAINER} ^
                      --network ${NETWORK} ^
                      -v ${DB_VOLUME}:/var/lib/postgresql/data ^
                      -e POSTGRES_DB=customerdb ^
                      -e POSTGRES_USER=customer ^
                      -e POSTGRES_PASSWORD=customer123 ^
                      postgres:16
                """
            }
        }

        stage('Deploy Application') {
            when {
                expression {
                    params.ACTION == 'DEPLOY'
                }
            }

            steps {
                bat """
                    docker rm -f ${APP_CONTAINER} >nul 2>&1 || exit /b 0

                    docker run -d ^
                      --name ${APP_CONTAINER} ^
                      --network ${NETWORK} ^
                      -p ${PORT}:8080 ^
                      -e ENVIRONMENT=${params.ENVIRONMENT} ^
                      -e DB_HOST=${DB_CONTAINER} ^
                      -e DB_NAME=customerdb ^
                      -e DB_USER=customer ^
                      -e DB_PASSWORD=customer123 ^
                      ${IMAGE_NAME}:${params.VERSION}
                """
            }
        }

        stage('Validate Deployment') {
            when {
                expression {
                    params.ACTION == 'DEPLOY'
                }
            }

            steps {
                bat """
                    timeout /t 5 /nobreak >nul

                    docker ps --filter "name=${APP_CONTAINER}"
                    docker ps --filter "name=${DB_CONTAINER}"

                    curl.exe -f http://localhost:${PORT}/health
                    curl.exe -f http://localhost:${PORT}/version
                    curl.exe -f http://localhost:${PORT}/db

                    docker network inspect ${NETWORK}
                """
            }
        }

        stage('Rollback') {
            when {
                expression {
                    params.ACTION == 'ROLLBACK'
                }
            }

            steps {
                echo "Rollback requested for ${params.ENVIRONMENT}"
                echo "Rollback version: ${params.VERSION}"

                bat """
                    docker rm -f ${APP_CONTAINER} >nul 2>&1 || exit /b 0
                """

                bat """
                    docker run -d ^
                      --name ${APP_CONTAINER} ^
                      --network ${NETWORK} ^
                      -p ${PORT}:8080 ^
                      -e ENVIRONMENT=${params.ENVIRONMENT} ^
                      -e DB_HOST=${DB_CONTAINER} ^
                      -e DB_NAME=customerdb ^
                      -e DB_USER=customer ^
                      -e DB_PASSWORD=customer123 ^
                      ${IMAGE_NAME}:${params.VERSION}
                """

                bat """
                    timeout /t 5 /nobreak >nul
                    curl.exe -f http://localhost:${PORT}/health
                    curl.exe -f http://localhost:${PORT}/version
                """
            }
        }
    }

    post {
        success {
            echo "DEPLOYMENT SUCCESSFUL"
        }

        failure {
            echo "DEPLOYMENT FAILED"
        }
    }
}