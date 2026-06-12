pipeline {
    agent any

    parameters {
        choice(
            name: 'action',
            choices: ['apply', 'destroy'],
            description: 'Terraform action to perform'
        )
    }

    environment {
        AWS_REGION   = "us-east-1"
        CLUSTER_NAME = "devops-eks-cluster"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-token',
                    url: 'https://github.com/hmurafique/DevOps-Project-012'
            }
        }

        stage('Terraform Init') {
            steps {
                dir('tf-aws-eks') {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('tf-aws-eks') {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh 'terraform validate'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('tf-aws-eks') {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh 'terraform plan'
                    }
                }
            }
        }

        stage('Approval') {
            steps {
                input message: "Approve Terraform ${params.action}?"
            }
        }

        stage('Terraform Apply/Destroy') {
            steps {
                dir('tf-aws-eks') {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh "terraform ${params.action} -auto-approve"
                    }
                }
            }
        }

        stage('Update Kubeconfig') {
            when {
                expression { params.action == 'apply' }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    sh "aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}"
                }
            }
        }

        stage('Deploy Nginx App') {
            when {
                expression { params.action == 'apply' }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    sh '''
                        kubectl apply -f manifest/deployment.yaml
                        kubectl apply -f manifest/service.yaml
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline ${params.action} completed successfully!"
        }
        failure {
            echo "Pipeline ${params.action} failed!"
        }
    }
}
