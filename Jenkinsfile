pipeline {
    agent any
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['DEV','UAT','PRODUCTION'], description: 'Target environment')
        choice(name: 'ACTION', choices: ['DEPLOY','ROLLBACK'], description: 'Deployment action')
        string(name: 'VERSION', defaultValue: '1.0', description: 'Application version')
        choice(name: 'RUN_TESTS', choices: ['YES','NO'], description: 'Run tests')
        booleanParam(name: 'PRODUCTION_CONFIRM', defaultValue: false, description: 'Required for production')
    }
    environment {
        IMAGE_REPO = 'customer-app'
        DB_PASSWORD = credentials('customer-db-password')
    }
    stages {
        stage('Resolve configuration') {
            steps {
                script {
                    def configs = [
                        DEV:[branch:'develop',app:'customer-app-dev',port:'8081',network:'customer-dev-net',db:'customer-db-dev',volume:'customer-db-dev-data'],
                        UAT:[branch:'release',app:'customer-app-uat',port:'8082',network:'customer-uat-net',db:'customer-db-uat',volume:'customer-db-uat-data'],
                        PRODUCTION:[branch:'main',app:'customer-app-prod',port:'8083',network:'customer-prod-net',db:'customer-db-prod',volume:'customer-db-prod-data']
                    ]
                    def c=configs[params.ENVIRONMENT]
                    if (!c) error('Invalid environment')
                    if (!params.VERSION?.trim()) error('VERSION is required')
                    if (params.ENVIRONMENT=='PRODUCTION' && !params.PRODUCTION_CONFIRM) error('Production requires explicit confirmation')
                    env.GIT_BRANCH_RESOLVED=c.branch
                    env.APP_CONTAINER=c.app
                    env.HOST_PORT=c.port
                    env.DOCKER_NETWORK=c.network
                    env.DB_CONTAINER=c.db
                    env.DB_VOLUME=c.volume
                    env.APP_IMAGE="${IMAGE_REPO}:${params.VERSION}"
                    echo "Environment=${params.ENVIRONMENT} Action=${params.ACTION} Version=${params.VERSION} Branch=${c.branch} App=${c.app} Port=${c.port} Network=${c.network} DB=${c.db} Volume=${c.volume}"
                }
            }
        }
        stage('Checkout') {
            steps {
                checkout([$class:'GitSCM', branches:[[name:"*/${env.GIT_BRANCH_RESOLVED}"]], userRemoteConfigs:[[url:'YOUR-GIT-REPOSITORY', credentialsId:'git-credentials']]])
            }
        }
        stage('Build Docker image') {
            when { expression { params.ACTION == 'DEPLOY' } }
            steps { sh "docker build -t ${APP_IMAGE} ./app" }
        }
        stage('Run tests') {
            when { expression { params.ACTION == 'DEPLOY' && params.RUN_TESTS == 'YES' } }
            steps { sh "docker run --rm ${APP_IMAGE} python -m py_compile app.py" }
        }
        stage('Prepare configuration') {
            steps {
                sh '''
                    export APP_IMAGE="${APP_IMAGE}"
                    export APP_CONTAINER="${APP_CONTAINER}"
                    export VERSION="${VERSION}"
                    export ENVIRONMENT="${ENVIRONMENT}"
                    export DB_CONTAINER="${DB_CONTAINER}"
                    export DB_PASSWORD="${DB_PASSWORD}"
                    export HOST_PORT="${HOST_PORT}"
                    export NETWORK="${DOCKER_NETWORK}"
                    export DB_VOLUME="${DB_VOLUME}"
                    envsubst < deploy/compose.template.yml > deploy/compose.yml
                    cat deploy/compose.yml
                '''
            }
        }
        stage('Deploy') {
            when { expression { params.ACTION == 'DEPLOY' } }
            steps { sh 'docker compose -f deploy/compose.yml up -d --force-recreate' }
        }
        stage('Rollback') {
            when { expression { params.ACTION == 'ROLLBACK' } }
            steps { sh 'docker compose -f deploy/compose.yml up -d --force-recreate' }
        }
        stage('Validation') {
            steps {
                sh '''
                    set -e
                    docker ps
                    docker network inspect ${DOCKER_NETWORK}
                    curl -f http://localhost:${HOST_PORT}/health
                    curl -f http://localhost:${HOST_PORT}/db
                    curl -f http://localhost:${HOST_PORT}/version
                '''
            }
        }
    }
    post {
        success { echo 'Deployment validation succeeded.' }
        failure { echo 'Deployment or validation failed.' }
    }
}
