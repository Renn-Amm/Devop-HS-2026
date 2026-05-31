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
                export PATH=/var/lib/jenkins/go/bin:$PATH
                cd app
        
                go mod init app || true
                go mod tidy || true
        
                go build -o main .
                '''
            }
        }

        stage('Deploy') {
            steps {
                sshagent (credentials: ['target-ssh']) {
                    sh '''
                    scp -o StrictHostKeyChecking=no app/main ubuntu@target:/tmp/main
        
                    ssh -o StrictHostKeyChecking=no ubuntu@target '
                        sudo mv /tmp/main /opt/myapp/main
                        sudo chmod +x /opt/myapp/main
                        sudo systemctl restart myapp
                    '
                    '''
                }
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
