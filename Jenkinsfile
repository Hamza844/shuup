pipeline {
    agent { label 'shuup' }

    stages {
        stage('Clone Repository') {
            steps {
                sh 'git clone --branch master https://github.com/Hamza844/shuup.git'
                echo "Repository cloned successfully"
            }
        }
    }
}
