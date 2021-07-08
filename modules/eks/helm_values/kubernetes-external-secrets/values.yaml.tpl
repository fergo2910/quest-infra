# Default values for kubernetes-external-secrets.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

# Determines whether the Helm chart or kubernetes-external-secrets
# will handle the ExternalSecret CRD
customResourceManagerDisabled: false

crds:
  # only needed for helm v2, leave this disabled for helm v3
  create: false

# Environment variables to set on deployment pod
env:
  AWS_REGION: us-west-2
  AWS_DEFAULT_REGION: us-west-2
  POLLER_INTERVAL_MILLISECONDS: 10000  # Caution, setting this frequency may incur additional charges on some platforms
  LOG_LEVEL: info
  LOG_MESSAGE_KEY: 'msg'
  # Print logs level as string ("info") rather than integer (30)
  # USE_HUMAN_READABLE_LOG_LEVELS: true
  METRICS_PORT: 3001
  VAULT_ADDR: http://127.0.0.1:8200
  # Set a role to be used when assuming roles specified in external secret (AWS only)
  # AWS_INTERMEDIATE_ROLE_ARN:
  # GOOGLE_APPLICATION_CREDENTIALS: /app/gcp-creds/gcp-creds.json



rbac:
  # Specifies whether RBAC resources should be created
  create: true

serviceAccount:
  # Specifies whether a service account should be created
  create: true
  # Specifies annotations for this service account
  %{ if irsa_arn != "" }
  annotations:
    eks.amazonaws.com/role-arn: ${ irsa_arn }
  %{ endif }
  # The name of the service account to use.
  # If not set and create is true, a name is generated using the fullname template
  name:

replicaCount: 1

#image:
#  repository: godaddy/kubernetes-external-secrets
#  tag: 8.1.2
#  pullPolicy: IfNotPresent
#  imagePullSecrets: []

nameOverride: ""
fullnameOverride: ${ fullname_override }

podAnnotations: {}
podLabels: {}

dnsConfig: {}

securityContext:
  runAsNonRoot: false
  # Required for use of IRSA, see https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts-technical-overview.html
  %{ if irsa_arn != "" }
  fsGroup: 65534
  %{ endif }

resources: {}
  # We usually recommend not to specify default resources and to leave this as a conscious
  # choice for the user. This also increases chances charts run on environments with little
  # resources, such as Minikube. If you do want to specify resources, uncomment the following
  # lines, adjust them as necessary, and remove the curly braces after 'resources:'.
  # limits:
  #   cpu: 100m
  #   memory: 128Mi
  # requests:
  #   cpu: 100m
  #   memory: 128Mi

nodeSelector: {}

tolerations:
  - key: "stable"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"

affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-type
          operator: In
          values:
          - stable

serviceMonitor:
  enabled: false
  interval: "30s"
  namespace: ""

  