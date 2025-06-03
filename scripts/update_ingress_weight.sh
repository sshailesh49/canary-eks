#!/bin/bash
SERVICE=$1
NEW_WEIGHT=$2

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: traffic-split
  annotations:
    alb.ingress.kubernetes.io/actions.canary: |
      {
        "type": "forward",
        "forwardConfig": {
          "targetGroups": [
            {"serviceName": "app-v1", "servicePort": 80, "weight": $((100 - NEW_WEIGHT))},
            {"serviceName": "$SERVICE", "servicePort": 80, "weight": $NEW_WEIGHT}
          ]
        }
      }
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - backend:
              service:
                name: canary
                port:
                  name: use-annotation
            pathType: ImplementationSpecific
EOF
