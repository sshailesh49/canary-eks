pipeline {
  agent any
  environment {
    KUBECTL_VERSION = 'v1.30.0'
    KUBECONFIG = credentials('eks-kubeconfig-id')
    THRESHOLD = '5'
  }
  stages {
    stage('Deploy Canary') {
      steps {
        sh 'kubectl apply -f manifests/ingress-canary.yaml'
      }
    }
    stage('Monitor Metrics') {
      steps {
        sh 'chmod +x scripts/monitor_metrics.sh'
        sh './scripts/monitor_metrics.sh $THRESHOLD'
      }
    }
    stage('Promote to 30%') {
      steps {
        sh './scripts/update_ingress_weight.sh app-v2 30'
      }
    }
    stage('Promote to 50%') {
      steps {
        sh './scripts/update_ingress_weight.sh app-v2 50'
      }
    }
    stage('Promote to 100%') {
      steps {
        sh './scripts/update_ingress_weight.sh app-v2 100'
      }
    }
  }
  post {
    failure {
      sh './scripts/update_ingress_weight.sh app-v2 0'
    }
  }
}
