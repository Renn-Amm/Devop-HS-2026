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

        stage('Docker Build and Push') {
            steps {
                sh '''
                    docker build -t ttl.sh/renn-amm:2h .
                    docker push ttl.sh/renn-amm:2h
                '''
            }
        }

        stage('Deploy to Docker VM') {
            steps {
                sh '''
                    mkdir -p ~/.ssh
                    ssh-keyscan -H docker >> ~/.ssh/known_hosts
                    ssh -i ~/.ssh/id_ed25519 laborant@docker "
                        docker pull ttl.sh/renn-amm:2h &&
                        docker rm -f myapp 2>/dev/null || true &&
                        docker run -d --name myapp -p 4444:4444 ttl.sh/renn-amm:2h
                    "
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    for i in $(seq 1 10); do
                        curl -fsS http://docker:4444/ && exit 0
                        sleep 3
                    done
                    exit 1
                '''
            }
        }
    }
}
