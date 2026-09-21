pipeline {
    agent any

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['DEV', 'UAT', 'PRODUCTION'],
            description: 'Select deployment environment'
        )

        choice(
            name: 'ACTION',
            choices: ['DEPLOY', 'ROLLBACK'],
            description: 'Select deployment action'
        )

        string(
            name: 'VERSION',
            defaultValue: '1.0',
            description: 'Docker image version'
        )

        choice(
            name: 'RUN_TESTS',
            choices: ['YES', 'NO'],
            description: 'Run application tests'
        )
    }

    stages {

        stage('Show Configuration') {
            steps {
                echo "========================================"
                echo "Environment : ${params.ENVIRONMENT}"
                echo "Action      : ${params.ACTION}"
                echo "Version     : ${params.VERSION}"
                echo "Run Tests   : ${params.RUN_TESTS}"
                echo "========================================"
            }
        }

        stage('Validate Parameters') {
            steps {
                script {
                    if (params.ENVIRONMENT == 'PRODUCTION' &&
                        params.VERSION == '') {
                        error('Production deployment requires a version.')
                    }

                    echo "Parameters validated successfully."
                }
            }
        }

        stage('Checkout') {
            steps {
                script {
                    def branch = ''

                    if (params.ENVIRONMENT == 'DEV') {
                        branch = 'develop'
                    } else if (params.ENVIRONMENT == 'UAT') {
                        branch = 'release'
                    } else if (params.ENVIRONMENT == 'PRODUCTION') {
                        branch = 'main'
                    }

                    echo "Checking out branch: ${branch}"

                    git branch: branch,
                        url: 'https://github.com/muralipadmaraju/customer-ci-cd-project.git'
                }
            }
        }

        stage('Tests') {
            when {
                expression {
                    params.RUN_TESTS == 'YES'
                }
            }

            steps {
                echo "Running application tests..."
            }
        }

        stage('Deploy') {
            when {
                expression {
                    params.ACTION == 'DEPLOY'
                }
            }

            steps {
                echo "Deployment requested."
                echo "Environment: ${params.ENVIRONMENT}"
                echo "Version: ${params.VERSION}"
            }
        }

        stage('Rollback') {
            when {
                expression {
                    params.ACTION == 'ROLLBACK'
                }
            }

            steps {
                echo "Rollback requested."
                echo "Environment: ${params.ENVIRONMENT}"
                echo "Version: ${params.VERSION}"
            }
        }
    }

    post {
        success {
            echo "========================================"
            echo "PIPELINE SUCCESSFUL"
            echo "========================================"
        }

        failure {
            echo "========================================"
            echo "PIPELINE FAILED"
            echo "========================================"
        }
    }
}