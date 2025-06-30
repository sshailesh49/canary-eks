#!/bin/bash

SERVICE=$1
NEW_WEIGHT=$2
OLD_WEIGHT=$((100 - NEW_WEIGHT))

cat <<EOM | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: traffic-split
  namespace: monitoring
  annotations:
    alb.ingress.kubernetes.io/group.name: traffic-split
    alb.ingress.kubernetes.io/load-balancer-name: traffic-split
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/actions.canary: |
      {
        "type": "forward",
        "forwardConfig": {
          "targetGroups": [
            { "serviceName": "app-v1", "servicePort": 80, "weight": $OLD_WEIGHT },
            { "serviceName": "$SERVICE", "servicePort": 80, "weight": $NEW_WEIGHT }
          ]
        }
      }
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: canary
                port:
                  name: use-annotation
EOM


