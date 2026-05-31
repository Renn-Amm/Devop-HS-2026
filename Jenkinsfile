pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                sh 'cd app && go build -o main .'
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                scp app/main target:/tmp/main

                ssh target '
                    sudo mv /tmp/main /opt/myapp/main
                    sudo chmod +x /opt/myapp/main
                    sudo systemctl restart myapp
                '
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                for i in $(seq 1 10); do
                    curl -fsS http://target:4444/ && exit 0
                    sleep 2
                done
                exit 1
                '''
            }
        }
    }
}
