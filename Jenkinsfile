pipeline {
    environment {
        registry = "dfcn0/docker-spring-boot"
        registryCredential = 'dockerhub_credentials'
        sonarCredential = 'sonarqube_credentials'
        awsCredentialsId = 'aws_credentials'

        clusterName = 'mykubernetes'
        region = 'us-east-1'
    }

    agent any

    stages {
        stage('Checkout Git') {
            steps {
                echo 'Cloning Git repository...'
                git branch: 'main', url: 'https://github.com/YassineSlaoui/docker-spring-boot-master.git'
            }
        }

        stage('Maven Clean') {
            steps {
                echo 'Cleaning the project...'
                sh 'mvn clean'
            }
        }

        stage('Artifact Construction') {
            steps {
                echo 'Constructing artifact...'
                sh 'mvn package -Dmaven.test.skip=true -P test-coverage'
            }
        }

        stage('Unit Tests') {
            steps {
                echo 'Running Unit Tests...'
                sh 'mvn test'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo 'Running SonarQube Analysis...'
                withCredentials([usernamePassword(credentialsId: sonarCredential, usernameVariable: 'SONAR_USER', passwordVariable: 'SONAR_PASS')]) {
                    sh '''
                    mvn sonar:sonar \
                        -Dsonar.host.url=http://sonarqube:9000 \
                        -Dsonar.login=$SONAR_USER \
                        -Dsonar.password=$SONAR_PASS
                    '''
                }
            }
        }

        stage('Publish to Nexus') {
            steps {
                echo 'Publishing artifact to Nexus...'
                sh 'mvn deploy'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Building Docker image...'
                    dockerImage = docker.build("${registry}:latest")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    echo "Pushing Docker image..."
                    docker.withRegistry('https://registry.hub.docker.com', registryCredential) {
                        dockerImage.push()
                    }
                }
            }
        }

        // New Stage to Test AWS Credentials
        stage('Test AWS Credentials') {
            steps {
                withCredentials([file(credentialsId: awsCredentialsId, variable: 'AWS_CREDENTIALS_FILE')]) {
                    script {
                        def awsCredentials = readFile(AWS_CREDENTIALS_FILE).trim().split("\n")
                        env.AWS_ACCESS_KEY_ID = awsCredentials.find { it.startsWith("aws_access_key_id") }.split("=")[1].trim()
                        env.AWS_SECRET_ACCESS_KEY = awsCredentials.find { it.startsWith("aws_secret_access_key") }.split("=")[1].trim()
                        env.AWS_SESSION_TOKEN = awsCredentials.find { it.startsWith("aws_session_token") }?.split("=")[1]?.trim()

                        echo "AWS Access Key ID: ${env.AWS_ACCESS_KEY_ID}"
                        // Optional: echo "AWS Session Token: ${env.AWS_SESSION_TOKEN}"

                        echo "AWS Credentials File Loaded"

                        // Test AWS Credentials
                        sh 'aws sts get-caller-identity' // Ensure AWS CLI can access the credentials
                    }
                }
            }
        }

        stage('Retrieve AWS Resources') {
            steps {
                withCredentials([file(credentialsId: awsCredentialsId, variable: 'AWS_CREDENTIALS_FILE')]) {
                    script {
                        def awsCredentials = readFile(AWS_CREDENTIALS_FILE).trim().split("\n")
                        env.AWS_ACCESS_KEY_ID = awsCredentials.find { it.startsWith("aws_access_key_id") }.split("=")[1].trim()
                        env.AWS_SECRET_ACCESS_KEY = awsCredentials.find { it.startsWith("aws_secret_access_key") }.split("=")[1].trim()
                        env.AWS_SESSION_TOKEN = awsCredentials.find { it.startsWith("aws_session_token") }?.split("=")[1]?.trim()

                        echo "AWS Access Key ID: ${env.AWS_ACCESS_KEY_ID}"
                        echo "AWS Credentials File Loaded"

                        // Retrieve role_arn
                        env.ROLE_ARN = sh(script: "aws iam list-roles --query 'Roles[?RoleName==`LabRole`].Arn' --output text", returnStdout: true).trim()
                        echo "Retrieved Role ARN: ${env.ROLE_ARN}"

                        // Retrieve VPC ID
                        env.VPC_ID = sh(script: "aws ec2 describe-vpcs --region ${region} --query 'Vpcs[0].VpcId' --output text", returnStdout: true).trim()
                        echo "Retrieved VPC ID: ${env.VPC_ID}"

                        // Retrieve Subnet IDs
                        def subnetIds = sh(script: """
                            aws ec2 describe-subnets --region ${region} \
                            --filters Name=vpc-id,Values=${env.VPC_ID} Name=availability-zone,Values=us-east-1a,us-east-1b \
                            --query 'Subnets[0:2].SubnetId' --output text
                        """, returnStdout: true).trim().split()
                        env.SUBNET_ID_A = subnetIds[0]
                        env.SUBNET_ID_B = subnetIds[1]
                        echo "Retrieved Subnet IDs: ${env.SUBNET_ID_A}, ${env.SUBNET_ID_B}"
                    }
                }
            }
        }

        stage('Terraform Setup') {
            steps {
                script {
                    // Initialize Terraform
                    sh 'terraform -chdir=terraform init'

                    // Validate Terraform configuration files
                    sh 'terraform -chdir=terraform validate'

                    // Apply the configuration changes
                    // sh 'terraform -chdir=terraform apply -auto-approve -var aws_region=${region} -var cluster_name=${clusterName}'
                    sh """
                        terraform -chdir=terraform apply -auto-approve \
                            -var aws_region=${region} \
                            -var cluster_name=${clusterName} \
                            -var role_arn=${env.ROLE_ARN} \
                            -var 'subnet_ids=[\"${env.SUBNET_ID_A}\",\"${env.SUBNET_ID_B}\"]'
                    """
                }
            }
        }

        // New Stage to Deploy on AWS Kubernetes (EKS)
        stage('Deploy to AWS Kubernetes (EKS)') {
            steps {
                script {
                    // Use the kubeconfig securely without string interpolation
                    sh """
                    aws eks update-kubeconfig --region ${region} --name ${clusterName}
                    kubectl apply -f deployment.yaml
                    kubectl apply -f service.yaml
                    """

                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}