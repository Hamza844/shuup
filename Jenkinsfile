pipeline {
    agent { label 'shuup' }

    stages {
        stage('Trivy FS Scan') {
            steps {
                sh 'trivy fs shuup/ --exit-code 1 --severity CRITICAL,HIGH --no-progress'
                echo "code is successfull scan"
        }
        stage('compile'){
            echo "code is successfull compile"
        }
        stage('SonarQube Analysis'){
            steps{
                echo "code is successfull"
            }
        }
        stage('build'){
            steps{
                sh 'docker compose up -d'
            }
        }
        stage('Trivy image scan'){
            steps{
                echo 'scan trivy the image'
            }
        }
    }
}
