pipeline {
    agent { label 'shuup' }

    stages {
        stage('build'){
            steps{
                sh 'docker build -t py_frits .'
            }
        }
        stage('test'){
            steps{
                echo "code is successfully test"
            }
        }
    }
}
