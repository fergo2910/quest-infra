fullnameOverride: ${ fullname_override }

replicaCount: 1

affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-type
          operator: In
          values:
          - stable
tolerations:
  - key: "stable"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"



serviceAccount:
  create: true
  name: "aws-container-insights"
  %{ if irsa_arn != "" }
  annotations:
    eks.amazonaws.com/role-arn: ${ irsa_arn }     
  %{ endif }

