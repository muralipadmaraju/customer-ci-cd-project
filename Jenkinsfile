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
            description: 'Required for production'
        )
    }

    environment {
        IMAGE_NAME = 'customer-app'
        DB_CREDENTIALS_ID = 'customer-db-credentials'
        DEPLOY_STARTED = 'false'
        PREVIOUS_IMAGE = ''
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

                    if (!params.VERSION?.trim()) {
                        error('VERSION cannot be empty.')
                    }

                    echo """
================================================
RESOLVED DEPLOYMENT CONFIGURATION
================================================
Environment : ${params.ENVIRONMENT}
Branch      : ${env.BRANCH}
Action      : ${params.ACTION}
Version     : ${params.VERSION}
App         : ${env.APP_CONTAINER}
Database    : ${env.DB_CONTAINER}
Network     : ${env.NETWORK}
Host Port   : ${env.PORT}
DB Volume   : ${env.DB_VOLUME}
================================================
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

        stage('Capture Previous Version') {
            when {
                expression {
                    params.ACTION == 'DEPLOY'
                }
            }

            steps {
                script {
                    def status = bat(
                        returnStatus: true,
                        script: """
                            docker inspect -f "{{.Config.Image}}" ${env.APP_CONTAINER} > previous-image.txt 2>nul
                        """
                    )

                    if (status == 0) {
                        env.PREVIOUS_IMAGE = readFile('previous-image.txt').trim()
                        echo "Previous image: ${env.PREVIOUS_IMAGE}"
                    }
                    else {
                        env.PREVIOUS_IMAGE = ''
                        echo "No previous application container found."
                    }
                }
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
                    docker build -t ${IMAGE_NAME}:${params.VERSION} ./app
                    docker image inspect ${IMAGE_NAME}:${params.VERSION}
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
                    docker network inspect ${NETWORK} >nul 2>&1
                    if errorlevel 1 docker network create ${NETWORK}
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
                withCredentials([
                    usernamePassword(
                        credentialsId: "${DB_CREDENTIALS_ID}",
                        usernameVariable: 'DB_USER',
                        passwordVariable: 'DB_PASSWORD'
                    )
                ]) {
                    bat '''
                        docker volume inspect %DB_VOLUME% >nul 2>&1
                        if errorlevel 1 docker volume create %DB_VOLUME%

                        docker inspect %DB_CONTAINER% >nul 2>&1

                        if errorlevel 1 (
                            docker run -d ^
                              --name %DB_CONTAINER% ^
                              --network %NETWORK% ^
                              -v %DB_VOLUME%:/var/lib/postgresql/data ^
                              -e POSTGRES_DB=customerdb ^
                              -e POSTGRES_USER=%DB_USER% ^
                              -e POSTGRES_PASSWORD=%DB_PASSWORD% ^
                              postgres:16
                        ) else (
                            docker start %DB_CONTAINER% >nul 2>&1
                        )

                        echo Waiting for PostgreSQL...

                        set DB_READY=0

                        for /L %%i in (1,1,12) do (
                            docker exec %DB_CONTAINER% pg_isready -U %DB_USER% -d customerdb >nul 2>&1
                            if not errorlevel 1 (
                                set DB_READY=1
                                goto DB_READY_DONE
                            )
                            timeout /t 2 /nobreak >nul
                        )

                        :DB_READY_DONE

                        if "%DB_READY%"=="0" (
                            echo PostgreSQL did not become ready.
                            exit /b 1
                        )

                        echo PostgreSQL is ready.
                    '''
                }
            }
        }

        stage('Deploy Application') {
            when {
                expression {
                    params.ACTION == 'DEPLOY'
                }
            }

            steps {
                script {
                    env.DEPLOY_STARTED = 'true'
                }

                withCredentials([
                    usernamePassword(
                        credentialsId: "${DB_CREDENTIALS_ID}",
                        usernameVariable: 'DB_USER',
                        passwordVariable: 'DB_PASSWORD'
                    )
                ]) {
                    bat '''
                        docker rm -f %APP_CONTAINER% >nul 2>&1

                        docker run -d ^
                          --name %APP_CONTAINER% ^
                          --network %NETWORK% ^
                          -p %PORT%:8080 ^
                          -e APP_VERSION=%VERSION% ^
                          -e APP_ENVIRONMENT=%ENVIRONMENT% ^
                          -e DB_HOST=%DB_CONTAINER% ^
                          -e POSTGRES_DB=customerdb ^
                          -e POSTGRES_USER=%DB_USER% ^
                          -e POSTGRES_PASSWORD=%DB_PASSWORD% ^
                          %IMAGE_NAME%:%VERSION%
                    '''
                }
            }
        }

        stage('Validate Deployment') {
            when {
                expression {
                    params.ACTION == 'DEPLOY'
                }
            }

            steps {
                bat '''
                    echo Checking application container...
                    docker inspect -f "{{.State.Running}}" %APP_CONTAINER% | findstr /I "true" >nul
                    if errorlevel 1 exit /b 1

                    echo Checking database container...
                    docker inspect -f "{{.State.Running}}" %DB_CONTAINER% | findstr /I "true" >nul
                    if errorlevel 1 exit /b 1

                    echo Checking Docker network...
                    docker network inspect %NETWORK% > network-inspect.json

                    findstr /C:"%APP_CONTAINER%" network-inspect.json >nul
                    if errorlevel 1 exit /b 1

                    findstr /C:"%DB_CONTAINER%" network-inspect.json >nul
                    if errorlevel 1 exit /b 1

                    echo Checking health endpoint...
                    curl.exe -fsS http://localhost:%PORT%/health > health.json

                    echo Checking version and environment...
                    curl.exe -fsS http://localhost:%PORT%/version > version.json

                    findstr /C:"\"version\":\"%VERSION%\"" version.json >nul
                    if errorlevel 1 exit /b 1

                    findstr /C:"\"environment\":\"%ENVIRONMENT%\"" version.json >nul
                    if errorlevel 1 exit /b 1

                    echo Checking database connectivity...
                    curl.exe -fsS http://localhost:%PORT%/db > db.json

                    echo Deployment validation successful.
                '''
            }
        }

        stage('Run Tests') {
            when {
                expression {
                    params.ACTION == 'DEPLOY' && params.RUN_TESTS == 'YES'
                }
            }

            steps {
                bat '''
                    curl.exe -fsS http://localhost:%PORT%/health
                    curl.exe -fsS http://localhost:%PORT%/db
                    echo Application tests passed.
                '''
            }
        }

        stage('Manual Rollback') {
            when {
                expression {
                    params.ACTION == 'ROLLBACK'
                }
            }

            steps {
                echo "Manual rollback requested."
                echo "Rollback version: ${params.VERSION}"

                bat """
                    docker image inspect ${IMAGE_NAME}:${params.VERSION} >nul 2>&1
                    if errorlevel 1 (
                        echo Rollback image does not exist.
                        exit /b 1
                    )
                """

                withCredentials([
                    usernamePassword(
                        credentialsId: "${DB_CREDENTIALS_ID}",
                        usernameVariable: 'DB_USER',
                        passwordVariable: 'DB_PASSWORD'
                    )
                ]) {
                    bat '''
                        docker rm -f %APP_CONTAINER% >nul 2>&1

                        docker run -d ^
                          --name %APP_CONTAINER% ^
                          --network %NETWORK% ^
                          -p %PORT%:8080 ^
                          -e APP_VERSION=%VERSION% ^
                          -e APP_ENVIRONMENT=%ENVIRONMENT% ^
                          -e DB_HOST=%DB_CONTAINER% ^
                          -e POSTGRES_DB=customerdb ^
                          -e POSTGRES_USER=%DB_USER% ^
                          -e POSTGRES_PASSWORD=%DB_PASSWORD% ^
                          %IMAGE_NAME%:%VERSION%

                        timeout /t 5 /nobreak >nul

                        curl.exe -fsS http://localhost:%PORT%/health
                        curl.exe -fsS http://localhost:%PORT%/version
                        curl.exe -fsS http://localhost:%PORT%/db
                    '''
                }
            }
        }
    }

    post {

        success {
            echo "DEPLOYMENT SUCCESSFUL"
        }

        failure {
            script {

                echo "DEPLOYMENT FAILED"

                if (
                    params.ACTION == 'DEPLOY' &&
                    env.DEPLOY_STARTED == 'true' &&
                    env.PREVIOUS_IMAGE?.trim()
                ) {

                    echo "========================================"
                    echo "AUTOMATIC ROLLBACK STARTED"
                    echo "Previous image: ${env.PREVIOUS_IMAGE}"
                    echo "========================================"

                    try {

                        withCredentials([
                            usernamePassword(
                                credentialsId: "${DB_CREDENTIALS_ID}",
                                usernameVariable: 'DB_USER',
                                passwordVariable: 'DB_PASSWORD'
                            )
                        ]) {

                            bat '''
                                docker rm -f %APP_CONTAINER% >nul 2>&1

                                docker run -d ^
                                  --name %APP_CONTAINER% ^
                                  --network %NETWORK% ^
                                  -p %PORT%:8080 ^
                                  -e APP_VERSION=%PREVIOUS_IMAGE:customer-app:=% ^
                                  -e APP_ENVIRONMENT=%ENVIRONMENT% ^
                                  -e DB_HOST=%DB_CONTAINER% ^
                                  -e POSTGRES_DB=customerdb ^
                                  -e POSTGRES_USER=%DB_USER% ^
                                  -e POSTGRES_PASSWORD=%DB_PASSWORD% ^
                                  %PREVIOUS_IMAGE%

                                timeout /t 5 /nobreak >nul

                                docker inspect -f "{{.State.Running}}" %APP_CONTAINER% | findstr /I "true" >nul
                                if errorlevel 1 exit /b 1

                                curl.exe -fsS http://localhost:%PORT%/health
                                curl.exe -fsS http://localhost:%PORT%/db
                            '''
                        }

                        echo "AUTOMATIC ROLLBACK COMPLETED."
                        echo "Restored image: ${env.PREVIOUS_IMAGE}"

                    } catch (Exception rollbackError) {
                        echo "AUTOMATIC ROLLBACK FAILED."
                        echo rollbackError.toString()
                    }
                }
                else {
                    echo "Automatic rollback not possible because no previous image was captured."
                }
            }
        }
    }
}