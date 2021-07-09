# Default values for nginx-ingress-controller.
# Ref: https://github.com/helm/charts/blob/master/stable/nginx-ingress/values.yaml

fullnameOverride: ${ fullname_override }

## nginx ingress-controller settings
controller:
  name: controller
  image:
    registry: k8s.gcr.io
    repository: ingress-nginx/controller
    tag: "v0.34.1"
    pullPolicy: IfNotPresent
    runAsUser: 101  # www-data

  # Name of the ingress class to route through this controller
  ingressClass: nginx

  config:
    use-forwarded-headers: "true"
    compute-full-forwarded-for: "true"
    use-proxy-protocol: "true"

  # Deployment type: DaemonSet or Deployment
  kind: Deployment

  # Service Type
  service:
    enableHttp: true
    enableHttps: true

    type: LoadBalancer
    nodePorts:
      http: ""
      https: ""

    targetPorts:
      http: http
      https: http

    externalTrafficPolicy: "Local"
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: '*'
      service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol: "true"
      service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "https"
      service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: '3600'
      service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"

  # Needed for external-dns to CNAME the ELB.
  # If false the DNS record will be an A record pointed to a specific node
  publishService:
    enabled: true

  # If true,  enable "vts-status" page (nginx virtual host traffic status)
  stats:
    enabled: false

  # If true, Prometheus metrics will be exported (vts stats has to be enabled)
  metrics:
    enabled: false

## Default 404 backend
defaultBackend:

  # If false, controller.defaultBackendService must be provided
  enabled: true

  name: default-backend
  image:
    repository: k8s.gcr.io/defaultbackend-amd64
    tag: "1.5"
    pullPolicy: IfNotPresent
    runAsUser: 65534  # nobody user -> uid 65534

rbac:
  create: true
  scope: false

%{ if irsa_arn != "" }
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: ${ irsa_arn }
%{ endif }
