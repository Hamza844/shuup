pipeline {
    agent { label 'shuup' }

    stages {
        stage('Checkout') {
            steps {
                echo "Repository cloned successfully"
            }
        }
        stage('build'){
            steps{
                sh 'docker build -t py_frits .'
            }
        }
    }
}
