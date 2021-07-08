fullnameOverride: ${ fullname_override }

image:
  repository: k8s.gcr.io/cluster-autoscaler
  tag: v1.17.1
  pullPolicy: IfNotPresent

# Only cloudProvider `aws` and `gce` are supported by auto-discovery at this time
# AWS: Set tags as described in https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#auto-discovery-setup
autoDiscovery:
    tags:
    - k8s.io/cluster-autoscaler/enabled
    - k8s.io/cluster-autoscaler/{{ .Values.autoDiscovery.clusterName }}
# Currently only `gce`, `aws`, `azure` & `spotinst` are supported
cloudProvider: aws

extraArgs:
  v: 4
  stderrthreshold: info
  logtostderr: true
  # scale-down-delay: 60m
  scale-down-enabled: true
  scale-down-unneeded-time: 10m
  scale-down-delay-after-add: 10m
  scale-down-delay-after-delete: 10m
  # write-status-configmap: true
  # leader-elect: true
  skip-nodes-with-local-storage: false
  expander: least-waste
  # balance-similar-node-groups: true
  # min-replica-count: 2
  # scale-down-utilization-threshold: 0.5
  # scale-down-non-empty-candidates-count: 5
  # max-node-provision-time: 15m0s
  # scan-interval: 10s
  # skip-nodes-with-system-pods: true
podDisruptionBudget: |
  maxUnavailable: 1
## Node labels for pod assignment
## Ref: https://kubernetes.io/docs/user-guide/node-selection/

affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-type
          operator: In
          values:
          - stable
nodeSelector: {}
tolerations:
  - key: "stable"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
podAnnotations: {}
podLabels: {}
replicaCount: 1
rbac:
  create: true
  pspEnabled: false
  %{ if irsa_arn != "" }
  serviceAccountAnnotations:
    eks.amazonaws.com/role-arn: ${ irsa_arn }
  %{ endif }
resources:
  limits:
    cpu: 100m
    memory: 300Mi
  requests:
    cpu: 60m
    memory: 50Mi
priorityClassName: ""
service:
  annotations: {}
  clusterIP: ""
  externalIPs: []
  loadBalancerIP: ""
  loadBalancerSourceRanges: []
  servicePort: 8085
  portName: http
  type: ClusterIP
## Are you using Prometheus Operator?
## Defaults to whats used if you follow CoreOS [Prometheus Install Instructions](https://github.com/helm/charts/tree/master/stable/prometheus-operator#tldr)
## [Prometheus Selector Label](https://github.com/helm/charts/tree/master/stable/prometheus-operator#prometheus-operator-1)
## [Kube Prometheus Selector Label](https://github.com/helm/charts/tree/master/stable/prometheus-operator#exporters)
# serviceMonitor:
#   enabled: false
#   interval: "10s"
#   namespace: monitoring
#   selector:
#     prometheus: kube-prometheus
    
