fullnameOverride: ${ fullname_override }

image:
  repository: k8s.gcr.io/metrics-server-amd64
  tag: v0.3.2
  pullPolicy: IfNotPresent

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