pipeline {
    agent { label 'shuup' }

    stages {
        stage('Checkout') {
            steps {
                sh 'git clone --branch master https://github.com/Hamza844/shuup.git'
                echo "Repository cloned successfully"
            }
        }
    }
}
