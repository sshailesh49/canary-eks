


@Library('Shared') _

pipeline {
  agent any

  environment {
    KUBECTL_VERSION = 'v1.30.0'
    THRESHOLD = '5'
    AWS_REGION = 'us-west-2'
    EKS_CLUSTER = 'my-eks-cluster'
  }

  stages {

    stage('Checkout from Git') {
      steps {
        script {
          code_checkout('https://github.com/sshailesh49/canary-eks.git', 'main', 'git-token')
        }
      }
    }

    stage('Deploy Canary') {
      steps {
        withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'shailesh-aws-id', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          sh '''
            aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER
            kubectl get all -A
          '''
        }
      }
    }

    stage('Monitor Initial Metrics') {
      steps {
        sh 'chmod +x scripts/monitor_metrics.sh'
        sh './scripts/monitor_metrics.sh'
      }
    }

    stage('Promote to 50%') {
      steps {
        withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'shailesh-aws-id', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          sh '''
            aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER
            chmod +x scripts/update_ingress_weight.sh
            ./scripts/update_ingress_weight.sh app-v2 50
          '''
        }
      }
    }

    stage('Monitor After 50%') {
      steps {
         sh 'chmod +x scripts/monitor_metrics.sh'
        sh './scripts/monitor_metrics.sh'
      }
    }

    stage('Promote to 100%') {
      steps {
        withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'shailesh-aws-id', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          sh '''
            aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER
             chmod +x scripts/update_ingress_weight.sh
            ./scripts/update_ingress_weight.sh app-v2 100
          '''
        }
      }
    }
  }

  post {
    failure {
      echo "❌ Pipeline failed. Reverting traffic to app-v1."
      withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'shailesh-aws-id', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
        sh '''
          aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER
           chmod +x scripts/update_ingress_weight.sh
          ./scripts/update_ingress_weight.sh app-v2 0
        '''
      }
    }
    success {
      echo "✅ Canary promotion to 100% successful."
    }
  }
}
