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
                    go mod init app 2>/dev/null || true
                    go mod tidy
                    go build -o main .
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    mkdir -p ~/.ssh
                    ssh-keyscan -H target >> ~/.ssh/known_hosts
                    scp -i ~/.ssh/id_ed25519 app/main laborant@target:/tmp/main
                    ssh -i ~/.ssh/id_ed25519 laborant@target "
                        sudo mv /tmp/main /opt/myapp/main &&
                        sudo chown myapp:myapp /opt/myapp/main &&
                        sudo chmod +x /opt/myapp/main &&
                        sudo systemctl restart myapp
                    "
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    for i in $(seq 1 10); do
                        curl -fsS http://target:4444/ && exit 0
                        sleep 3
                    done
                    exit 1
                '''
            }
        }
    }
}
