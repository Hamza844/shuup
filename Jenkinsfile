pipeline {
    agent { label 'shuup' }

    stages {
        stage('test'){
            steps{
                echo "code is successfully test"
            }
        }
        stage('build'){
            steps{
                sh 'docker build -t py_frits .'
            }
        }
    }
}
