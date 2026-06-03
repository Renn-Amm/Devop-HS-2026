pipeline {
    agent any

    environment {
        EC2_IP = "100.31.250.93"
    }

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
                    go mod init app 2>/dev/null || true
                    go mod tidy
                    go build -o main .
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'ec2-ssh-key',
                    keyFileVariable: 'SSH_KEY',
                    usernameVariable: 'SSH_USER'
                )]) {
                    sh '''
                        mkdir -p ~/.ssh
                        ssh-keyscan -H $EC2_IP >> ~/.ssh/known_hosts
                        scp -i $SSH_KEY app/main $SSH_USER@$EC2_IP:/tmp/main
                        ssh -i $SSH_KEY $SSH_USER@$EC2_IP "
                            sudo mv /tmp/main /opt/myapp/main &&
                            sudo chown myapp:myapp /opt/myapp/main &&
                            sudo chmod +x /opt/myapp/main &&
                            sudo systemctl restart myapp
                        "
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    for i in $(seq 1 10); do
                        curl -fsS http://$EC2_IP:4444/ && exit 0
                        sleep 5
                    done
                    exit 1
                '''
            }
        }
    }
}
