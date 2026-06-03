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

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([string(credentialsId: 'k8s-token', variable: 'K8S_TOKEN')]) {
                    sh '''
                        kubectl config set-cluster k8s \
                            --server=https://kubernetes:6443 \
                            --insecure-skip-tls-verify=true
                        kubectl config set-credentials jenkins-robot \
                            --token=$K8S_TOKEN
                        kubectl config set-context k8s \
                            --cluster=k8s \
                            --user=jenkins-robot
                        kubectl config use-context k8s
                        kubectl delete pod myapp --ignore-not-found
                        kubectl apply -f k8s_deploy/pod.yaml
                        kubectl wait --for=condition=Ready pod/myapp --timeout=60s
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                withCredentials([string(credentialsId: 'k8s-token', variable: 'K8S_TOKEN')]) {
                    sh '''
                        kubectl config use-context k8s
                        POD_IP=$(kubectl get pod myapp -o jsonpath='{.status.podIP}')
                        for i in $(seq 1 10); do
                            curl -fsS http://$POD_IP:4444/ && exit 0
                            sleep 3
                        done
                        exit 1
                    '''
                }
            }
        }
    }
}
