# Custom values for external-DNS that override the default ones.
# Ref: https://github.com/helm/charts/tree/master/stable/external-dns#configuration
fullnameOverride: ${ fullname_override }

## The DNS provider where the DNS records will be created
provider: aws
image:
  registry: docker.io
  name: bitnami/external-dns
  tag: 0.6.0
  pullPolicy: IfNotPresent
# Resource types externalDNS should watch for new DNS entries
sources:
  - ingress
  - service
## TODO: Limit target Hosted Zones by zone ID
policy: sync
aws:
  zoneType: ""
logLevel: warning
# Registry to use for ownership
registry: "txt"
# TODO: A name that identifies this instance of ExternalDNS
txtOwnerId: "external-dns"
# How DNS records are sychronized between sources and providers (options: sync, upsert-only )
# sync: allows full synchronization of DNS records
# upsert-only: allows evrything but deleting DNS records (create & update operations)
rbac:
  serviceAccountCreate: true
  %{ if irsa_arn != "" }
  serviceAccountAnnotations:
    eks.amazonaws.com/role-arn: ${ irsa_arn }
  %{ endif }
    
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
          
