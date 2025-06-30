                                    Canary Deployment Custom  ,  Prometheus  ,HPA 
# Create Cluster
eksctl create cluster   --profile ram   --name my-eks-cluster   --region us-west-2   --version 1.29   --nodegroup-name standard-workers   --node-type t2.medium   --nodes 1   --nodes-min 1   --nodes-max 3   --node-volume-size 20   --managed   --with-oidc
# canary-deployment
# ✅ Step 1: Enable IAM OIDC Provider for your EKS cluster
  export AWS_PROFILE=ram    # aws profile name
  
  eksctl utils associate-iam-oidc-provider \
  --cluster CLUSTER_NAME \
  --region us-west-2 \
  --approve
 
# ✅ Step 2: Create IAM Policy for ALB Controller

  curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

  aws iam create-policy \
      --policy-name AWSLoadBalancerControllerIAMPolicy \
      --region us-west-2 \
      --policy-document file://iam-policy.json

  # ✅ Step 3: Create IAM Role for ServiceAccount (IRSA)
    find account id : 
    aws_account_id=$(aws sts get-caller-identity --query Account --output text)

    eksctl create iamserviceaccount \
       --cluster $CLUSTER_NAME \
       --namespace kube-system \
       --region $REGION \
       --name aws-load-balancer-controller \
       --attach-policy-arn arn:aws:iam::${aws_account_id}:policy/AWSLoadBalancerControllerIAMPolicy \
       --approve

# OR 

    eksctl create iamserviceaccount \
          --cluster $CLUSTER_NAME \
          --namespace kube-system \
          --region us-west-2 \
          --name aws-load-balancer-controller \
          --attach-policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/AWSLoadBalancerControllerIAMPolicy \
          --approve

  # ✅ cert-manager Install with kubectl (v1.14.4)
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml

  # ✅ Step 4: Install AWS Load Balancer Controller using Helm
  #  Add Helm repo & update:
       helm repo add eks https://aws.github.io/eks-charts
       helm repo update

  # 🔹 Install the controller:
    helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=<your-cluster-name> \
    --set serviceAccount.create=false \
    --set region=<your-region> \
    --set vpcId=<your-vpc-id> \
    --set serviceAccount.name=aws-load-balancer-controller

Note : vpc-id cmd:
       aws eks describe-cluster --region us-west-2  --name my-eks-cluster   --query "cluster.resourcesV
pcConfig.vpcId"   --output text

# OP Upgrade the controller:
     helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
         -n kube-system \
         --set clusterName=$CLUSTER_NAME \
         --set serviceAccount.create=false \
         --set serviceAccount.name=aws-load-balancer-controller \
         --set region=$REGION \
         --set vpcId=<VPC_ID> \
        --set image.tag="v2.7.1"

# ✅ Step 5: Validate Controller is Running
   kubectl get deployment -n kube-system aws-load-balancer-controller
   kubectl describe ingress <your-ingress-name>

# Delete Ingress 
 kubectl delete ingress <your-ingress-name> -n <namespace>
#  Alternate (Hard Force)
kubectl delete ingress <your-ingress-name> -n <namespace> --grace-period=0 --force
# Restart controller 
kubectl -n kube-system rollout restart deployment aws-load-balancer-controller


projects  :







project-root/
├── Jenkinsfile
  |- ---- monitoring /
            |-- prometheus-configmap.yaml
            |---- prometheus-deployment -services.yaml
├── manifests/
│   ├── deployment-app-v1.yaml
│   ├── deployment-app-v2.yaml
│   ├── service-app-v1.yaml
│   ├── service-app-v2.yaml
│   └── ingress-canary.yaml
├── scripts/
│   ├── monitor_metrics.sh
│   └── update_ingress_weight.sh
└── README.md

-------------------------------------------------------------------------------------------------------------------------------------
# ✅ Option 1: Helm के ज़रिए Prometheus Setup (Recommended for Production)
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
 helm repo update
 helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false



---

## ✅ Step-by-Step: Install Prometheus in monitoring and Scrape Django Pod
---

## 🔹 Step 1: Add Prometheus Helm Repo


helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
## 🔹 Step 2: Create monitoring Namespace
  kubectl create namespace monitoring

## 🔹 Step 3: Install Prometheus Stack in monitoring

bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false


Note  This tells Prometheus to scrape all PodMonitors in the same namespace (monitoring), without needing label selectors.

---

## 🔹 Step 4: Deploy Django App in monitoring Namespace

### Example Deployment.yaml:

yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: django-app
  namespace: monitoring
  labels:
    app: django-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: django-app
  template:
    metadata:
      labels:
        app: django-app
    spec:
      containers:
        - name: django
          image: : shailesh49/myappv2
          ports:
            - containerPort: 8000


---

### Example Service.yaml:

yaml
apiVersion: v1
kind: Service
metadata:
  name: django-service
  namespace: monitoring
  labels:
    app: django-app
spec:
  selector:
    app: django-app
 type: NodePort
  ports:
    - name: http
      port: 8000
      targetPort: 8000
      nodePort: 30000


---

## 🔹 Step 5: Create PodMonitor.yaml

yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: django-podmonitor
  namespace: monitoring
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: django-app
  podMetricsEndpoints:
    - path: /metrics
      port: http
      interval: 30s
namespaceSelector:
    matchNames:
      - monitoring  


> Ensure port: http matches the port name in your Service.

---

## 🔹 Step 6: Verify Targets in Prometheus UI

### Port forward Prometheus:

bash
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090 -n monitoring


### Visit:

[http://localhost:9090/targets](http://localhost:9090/targets)

✅ You should see:

* /metrics from django-podmonitor
* Status: *UP*

---

## 🧪 Optional: Check with curl

To debug inside the cluster:

bash
kubectl exec -n monitoring -it <django-pod-name> -- curl http://localhost:8000/metrics


---



Promethuas  install 

# 🔹 Step 2: Create Namespace 
     kubectl create namespace monitoring

# Create a custom values.yaml file 
   
 # prometheus-values.yaml
server:
  service:
    type: NodePort       # 👈 NodePort enable
    nodePort: 30090      # 👈 Custom NodePort (access at <NodeIP>:30090)

  persistentVolume:
    enabled: false       # Disable PVC for simplicity

  global:
    scrape_interval: 15s # Default scrape interval

  podMonitor:
    enabled: true

  resources: {}
  tolerations: []
  affinity: {}

alertmanager:
  enabled: true
  persistentVolume:
    enabled: false       # Disable PVC for Alertmanager

# Collect pod metrics
kubelet:
  serviceMonitor:
    enabled: true
    https: true
    insecureSkipVerify: true
    port: 10250

#    Helm Install Command

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update

   helm install prometheus prometheus-community/prometheus \
       --namespace monitoring \
      --create-namespace \
     -f prometheus-values.yaml

#  If  use ClusterIP service UI Access (Port Forward)
   kubectl port-forward -n monitoring svc/prometheus-server 9090:80

# PUBLIC IP EKS NODES 
  aws ec2 describe-instances   --filters "Name=tag:eks:cluster-name,Values=my-eks-cluster"            "Name=instance-state-name,Values=running" --region us-west-2  --query "Reservations[*].Instances[*].PublicIpAddress"   --output text

# CUSTOM INSTALL PROMETHEUS   NOT USE MOSTLY

  # ===============================
# PROMETHEUS SETUP WITH CUSTOM YAML (NodePort + LoadBalancer Option)
# ===============================

---
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s

    scrape_configs:
      - job_name: 'kubernetes-nodes'
        static_configs:
          - targets: ['localhost:9100']
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
        - name: prometheus
          image: prom/prometheus:v2.52.0
          args:
            - "--config.file=/etc/prometheus/prometheus.yml"
          ports:
            - containerPort: 9090
          volumeMounts:
            - name: config-volume
              mountPath: /etc/prometheus/
      volumes:
        - name: config-volume
          configMap:
            name: prometheus-config

---
apiVersion: v1
kind: Service
metadata:
  name: prometheus-service-nodeport
  namespace: monitoring
spec:
  type: NodePort
  selector:
    app: prometheus
  ports:
    - name: web
      port: 80
      targetPort: 9090
      nodePort: 30090  # Accessible on <NodeIP>:30090

---
apiVersion: v1
kind: Service
metadata:
  name: prometheus-service-lb
  namespace: monitoring
spec:
  type: LoadBalancer
  selector:
    app: prometheus
  ports:
    - name: web
      port: 80
      targetPort: 9090
  

kubectl apply -f prometheus-deployment.yaml
--------------------------------------------------------------------------------------------------------------------------------------
# Not Tested
# ✅ HPA: Configure HPA with Prometheus (Using Prometheus Adapter 
# 🔷 1. Install Prometheus Adapter using Helm

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo update

  helm install prometheus-adapter prometheus-community/prometheus-adapter \
      --namespace monitoring \
      --create-namespace \
      --set prometheus.url=http://prometheus-service-clusterip.monitoring.svc \
     --set prometheus.port=9090

Note: prometheus-service-clusterip  =  ClusterIP Services 

# 🔷 2. Verify API Aggregation  (Prometheus Adapter custom metrics expose)
   kubectl get --raw /apis/custom.metrics.k8s.io/v1beta1 | jq .

# Custom Metrics for Prometheus Adapter
 apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-metrics-config
  namespace: monitoring
data:
  config.yaml: |
    rules:
      - seriesQuery: 'http_requests_total{namespace!="",pod!=""}'  
        resources:
          overrides:
            namespace:
              resource: namespace
            pod:
              resource: pod
        name:
          matches: "http_requests_total"
          as: "http_requests_per_second"
        metricsQuery: rate(http_requests_total{<<.LabelMatchers>>}[1m])

👉 Note : only who pods  consider that Namespace an pod are defined 
                      (- seriesQuery: 'http_requests_total{namespace!="",pod!=""}'  )
👉 Meaning: A way to link a Prometheus label to a Kubernetes object.
                                resources:
                                        overrides:
                                            namespace:
                                               resource: namespace
                                           pod:
                                             resource: pod
👉 Meaning: HPA will get a metric named "http_requests_per_second".
            name:
                matches: "http_requests_total"
                as: "http_requests_per_second"

👉 Meaning: The Prometheus adapter dynamically extracts metrics of the correct pod by adding labels at runtime.
    (metricsQuery: rate(http_requests_total{<<.LabelMatchers>>}[1m]))


# OR Second  Way to write  Above file
  rules:
   external:
      - seriesQuery: 'http_requests_total{kubernetes_namespace!="",kubernetes_pod_name!=""}'
        resources:
           overrides:
               kubernetes_namespace: {resource: "namespace"}
              kubernetes_pod_name: {resource: "pod"}
       name:
         matches: "http_requests_total"
         as: "http_requests"
      metricsQuery: sum(rate(http_requests_total{job="my-app"}[2m]))


# HPA YAML 
 apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 1
  maxReplicas: 10
  metrics:
    - type: External
      external:
        metric:
          name: http_requests
        target:
          type: Value
          value: 100






  




# canary-eks
