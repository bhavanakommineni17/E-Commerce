pipeline {
    agent any

    environment {
        COMPOSE_PROJECT_NAME = 'ecom'
        DOCKER_BUILDKIT = '1'
    }

    options {
        timeout(time: 20, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Checkout Source') {
            steps {
                echo 'Checking out source repository...'
                checkout scm
            }
        }

        stage('Backend Unit Tests') {
            steps {
                echo 'Validating backend service...'
                dir('backend') {
                    sh 'npm ci'
                    sh 'npm test'
                }
            }
        }

        stage('Frontend Unit Tests') {
            steps {
                echo 'Validating frontend application...'
                dir('frontend') {
                    sh 'npm ci'
                    sh 'npm test'
                }
            }
        }

        stage('Validate Compose Configuration') {
            steps {
                echo 'Validating docker-compose.yml configuration...'
                sh 'docker compose config'
            }
        }

        stage('Build & Deploy Stack') {
            steps {
                echo 'Building and starting MERN stack with Docker Compose...'
                sh 'docker compose down --remove-orphans'
                sh 'docker compose up -d --build'
            }
        }

        stage('Integration Health Check') {
            steps {
                echo 'Verifying end-to-end service readiness...'
                sh '''
                    echo "Awaiting stack readiness..."
                    MAX_RETRIES=20
                    COUNT=0
                    until curl -sf http://localhost:5000/health | grep -q '"status":"UP"'; do
                        COUNT=$((COUNT+1))
                        if [ $COUNT -ge $MAX_RETRIES ]; then
                            echo "ERROR: Backend and MongoDB failed healthcheck."
                            docker compose logs
                            exit 1
                        fi
                        echo "Waiting for services to become healthy... ($COUNT/$MAX_RETRIES)"
                        sleep 3
                    done
                    echo "SUCCESS: Backend and MongoDB are UP and healthy!"
                    
                    # Verify Frontend
                    curl -sf http://localhost:3000 > /dev/null && echo "SUCCESS: Frontend is serving traffic!"
                '''
            }
        }
    }

    post {
        failure {
            echo 'Deployment or tests failed! Collecting container logs...'
            sh 'docker compose logs --tail=100'
        }
        success {
            echo 'MERN application successfully deployed and verified via Docker Compose!'
        }
        always {
            cleanWs()
        }
    }
}
