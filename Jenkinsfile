pipeline {
    agent { label 'shuup' }

    stages {
        stage('Trivy FS Scan') {
            steps {
                sh 'trivy fs shuup/ --exit-code 1 --severity CRITICAL,HIGH --no-progress'
                echo "code is successful scan"
            }
        }

        stage('compile') {
            steps {
                echo "code is successful compile"
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo "code is successful"
            }
        }

        stage('build') {
            steps {
                sh 'docker compose up -d'
            }
        }

        stage('Trivy image scan') {
            steps {
                echo 'scan trivy the image'
            }
        }
    }
}
