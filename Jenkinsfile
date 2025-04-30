pipeline {
    agent { label 'shuup' }

    stages {
        stage('Checkout') {
            steps {
                // Clone only the master branch
                sh 'git clone --branch master https://github.com/Hamza844/shuup.git'
                echo "Master branch cloned successfully"
            }
        }
    }
}
