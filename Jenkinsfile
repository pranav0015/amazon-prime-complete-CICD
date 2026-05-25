pipeline {
    agent any
    
    tools{
        jdk "JDK21"
        nodejs "NodeJS"
    }

    parameters{
        string(name: 'ECR_REPO_NAME', defaultValue: 'amazon-prime', description: 'Enter Repository Name')
        string(name: 'AWS_ACCOUNT_ID', defaultValue: '', description: 'Enter AWS Account ID')
    }
    environment{
        SONAR_HOME = tool "sonar-scanner"
    }

    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'main', credentialsId: 'github-cred', url: 'https://github.com/pranav0015/amazon-prime-complete-CICD.git'
            }
        }
    
        stage('NPM Install') {
            steps {
                sh "npm install"
            }
        }

        stage('Compile') {
            steps {
                sh "npm run build"
            }
        }


        stage('Test') {
            steps {
                sh "npm test"
            }
        }

        stage('Trivy Scanning') {
            steps {
                sh "trivy fs --format table trivy-file-report.html ."
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner \
                    -Dsonar.projectName=amazonPrime \
                    -Dsonar.projectKey=amazonPrime
                    '''
                }
            }
        }

        stage('SonarQube Quality Gate') {
            steps {
                waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'  // abortPipeline: false means if code is coverage is not passing 85%(whatever we set), pipeline will not execute further, it will stop.
            }
        }

        stage('Build') {
            steps {
                sh "npm run build"
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${params.ECR_REPO_NAME} ."
            }
        }

        stage('Docker Image Scan') {
            steps {
               sh "trivy image --format table trivy-docker-image-scan-report.html ${params.ECR_REPO_NAME}"
            }
        }

        stage('Create ECR Repo') {
            steps {
               withCredentials([string(credentialsId: 'iam-user-access-key', variable: 'AWS_ACCESS_KEY'), string(credentialsId: 'iam-user-secret-key', variable: 'AWS_SECRET_KEY')]) {
                    // aws ecr describe repositories command will check if repo already existed. If existed it will not create, if not it will create ECR repo.

                    sh """
                    aws configure set aws_access_key_id $AWS_ACCESS_KEY
                    aws configure set aws_secret_access_key $AWS_SECRET_KEY
                    aws ecr describe-repositories --repository-names ${params.ECR_REPO_NAME} --region ap-south-1 ||   
                    aws ecr create-repository --repository-name ${params.ECR_REPO_NAME} --region ap-south-1
                    """
                }
            }
        }


        stage('Login to ECR and Tagging the Image') {
            steps {
               withCredentials([string(credentialsId: 'iam-user-access-key', variable: 'AWS_ACCESS_KEY'), string(credentialsId: 'iam-user-secret-key', variable: 'AWS_SECRET_KEY')]) {
                    // for below command, create a test ECR repo and modify the commands as per our configuration and need.
                    sh """
                    aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin ${params.AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com
                    docker tag ${params.ECR_REPO_NAME}:latest ${params.AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/${params.ECR_REPO_NAME}:$BUILD_NUMBER 
                    docker tag ${params.ECR_REPO_NAME}:latest ${params.AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/${params.ECR_REPO_NAME}:latest
                    """
                }
            }
        }
            
        stage('Push Images ECR') {
            steps {
               withCredentials([string(credentialsId: 'iam-user-access-key', variable: 'AWS_ACCESS_KEY'), string(credentialsId: 'iam-user-secret-key', variable: 'AWS_SECRET_KEY')]) {
                    sh """
                    docker push ${params.AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/${params.ECR_REPO_NAME}:$BUILD_NUMBER
                    docker push ${params.AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/${params.ECR_REPO_NAME}:latest
                    """
                }
            }
        }

        stage('Cleanup Images from Jenkins Server') { // once the impages push to ECR delete it from Jenkins server in order to clearn unnecessary space.
            steps {
                    sh """
                    docker rmi ${params.AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/${params.ECR_REPO_NAME}:$BUILD_NUMBER
                    docker rmi ${params.AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/${params.ECR_REPO_NAME}:latest
                    docker images
                    """
            }
        }

    }   
}