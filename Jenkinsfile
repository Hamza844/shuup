pipeline{
    agent {label, shuup}
    stages{
        stage(build){
            steps{
                sh 'docker build -t frontend .'
                sh 'docker images'
            }       
        }
        stage(test){
            steps{
                echo "code is successfully build"
                sh 'uname'
            }
        }
    }
}