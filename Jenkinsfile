pipeline {
    agent any

    stages {

        stage('Setup Go') {
            steps {
                sh '''
                curl -LO https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
                rm -rf $HOME/go
                tar -C $HOME -xzf go1.22.0.linux-amd64.tar.gz
                export PATH=$HOME/go/bin:$PATH
                go version
                '''
            }
        }

        stage('Build') {
            steps {
                sh '''
                export PATH=$HOME/go/bin:$PATH
                cd app
                go build -o main .
                '''
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
