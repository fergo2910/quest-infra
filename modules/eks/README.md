# Terraform module for AWS EKS service

Terraform module which creates an AWS EKS Kubernetes cluster in a given VPC.

At the moment it only supports Amazon Linux2 image optimized for EKS K8S workers
but the support of Ubuntu 18.04 for EKS workers is planned as a future improvement.

The module supports encryption at rest. In that case the official AMI is copied
and encrypted so workers are launched from the encrypted image making the EBS
boot volume encrypted by default at launch time.

When the cluster is created, the config map aws-auth is deployed by default,
allowing the workers to join the masters automatically. Also, a service account
for Tiller (server-side of Helm) is created with cluster-admin permissions,
so you can deploy Charts on top of this cluster.

Lastly, some additional IAM policies are created and attached to the worker nodes
so features like cluster autoscaler or external-DNS can be implemented without
additional work from the IAM side.

## Basic usage example

```hcl
module "eks_cluster" {
  source    = "./modules/eks"

  # Network settings
  vpc_id              = "vpc-ag6bc3az93f4e5122"
  vpc_cidr            = "172.18.0.0/16"
  public_subnets_ids  = ["subnet-773cc128", "subnet-fg9c73zf"]
  private_subnets_ids = ["subnet-103fe69a", "subnet-1490799f"]

  # EKS settings
  cluster_name             = "test-eks-cluster"
  # The Kubernetes master version
  k8s_version              = "1.13"
  # The image to be used for EKS workers;
  amzn_eks_worker_ami_name = "amazon-eks-node-1.13-v20190701"

  # Find available worker AMIs from EC2 > AMI
  workers_instance_type = "t2.medium"
  keypair_name          = "dev-caylent"
  boot_volume_size      = "20"
  encrypted_boot_volume = "false"
  asg_min_size          = "2"
  asg_desired_size      = "3"
  asg_max_size          = "4"
  environment           = "test"

  kms_key_arns              = ""
  docker_encrypted_password = "test"

  # Additional tags to be added to the AutoScaling Group (workers)
  tags = list(
      map("key", "App", "value", "Web", "propagate_at_launch", true),
      map("key", "Environment", "value", "development", "propagate_at_launch", true)
    )
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.13.4 |
| aws | ~> 3.10.0 |
| helm | ~> 1.3.2 |
| helm | ~> 1.3.2 |
| kubectl | ~> 1.7.2 |
| kubectl | ~> 1.7.0 |
| kubernetes | ~> 1.7 |
| kubernetes | ~> 1.13.2 |
| template | ~> 2.1 |
| template | ~> 2.2.0 |
| tls | ~> 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.10.0 |
| helm | ~> 1.3.2 ~> 1.3.2 |
| kubectl | ~> 1.7.2 ~> 1.7.0 |
| kubernetes | ~> 1.7 ~> 1.13.2 |
| local | n/a |
| template | ~> 2.1 ~> 2.2.0 |
| tls | ~> 3.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_irsa | Map of objects with definitions for additional IAM roles for service accounts (IRSA) | <pre>map(object({<br>    policy_arns               = list(string)<br>    service_account_name      = string<br>    service_account_namespace = string<br>  }))</pre> | `{}` | no |
| additional\_namespaces | A list of additional namespaces to create in cluster | `list(string)` | `[]` | no |
| addon\_helm\_release\_params | A composite map containing a set of key/value pairs overriding addon helm releases | `any` | `{}` | no |
| addon\_options | Map of addon-specific options to customize deployment | `any` | `{}` | no |
| addons | List of addons to install in the EKS cluster. Supported values: "aws-alb-ingress-controller", "aws-node-termination-handler", "cluster-autoscaler", "external-dns", "metrics-server", "nginx-ingress-controller". | `list(string)` | <pre>[<br>  "cluster-autoscaler",<br>  "metrics-server"<br>]</pre> | no |
| allow\_app\_ports | A list of TCP ports to open in the K8S workers SG for instances/services in the VPC | `list(string)` | <pre>[<br>  "22"<br>]</pre> | no |
| amzn\_eks\_worker\_ami\_name | The name of the AMI to be used. Right now only supports Amazon Linux2 based EKS worker AMI | `any` | n/a | yes |
| asg\_enabled\_metrics | Listo of ASG CloudWatch metrics to be enabled | `list` | <pre>[<br>  "GroupDesiredCapacity",<br>  "GroupInServiceCapacity",<br>  "GroupInServiceInstances",<br>  "GroupMaxSize",<br>  "GroupMinSize",<br>  "GroupPendingCapacity",<br>  "GroupPendingInstances",<br>  "GroupStandbyCapacity",<br>  "GroupStandbyInstances",<br>  "GroupTerminatingCapacity",<br>  "GroupTerminatingInstances",<br>  "GroupTotalCapacity",<br>  "GroupTotalInstances"<br>]</pre> | no |
| asg\_tags | A list of maps of tags to add to the autoscaling group if using K8S autoscaler | `map(string)` | `{}` | no |
| aws\_profile | AWS CLI Profile to be used | `string` | `""` | no |
| boot\_volume\_size | The size of the root volume in GBs | `number` | `200` | no |
| boot\_volume\_type | The type of volume to allocate [gp2\|io1] | `string` | `"gp2"` | no |
| chart\_deployment\_wait | If Terraform waits for all k8s objects to be in a ready state before marking the release as successful | `bool` | `true` | no |
| cluster\_log\_types | A list of the desired control plane logging to enable. | `list(string)` | `[]` | no |
| cluster\_name | The name of the EKS cluster | `any` | n/a | yes |
| create\_environment\_namespace | Create a default namespace matching the environment name | `string` | `true` | no |
| create\_metrics\_namespace | Create a metrics namespace for the metrics server | `string` | `true` | no |
| deployment\_timeout | Max time in seconds to wait for any individual kubernetes operation (if wait set to true) | `number` | `600` | no |
| disable\_helm\_plugins | True if we want to disable Helm plugins | `bool` | `false` | no |
| docker\_email | The email registered in the DockerHub account | `string` | `""` | no |
| docker\_encrypted\_password | The KMS encrypted password (ciphertext) of the docker user | `string` | `""` | no |
| docker\_registry\_secret | True if we want to create a secret object to pull images from Docker Hub | `bool` | `false` | no |
| docker\_secret\_name | The name of the secret object to create in the k8s cluster | `string` | `"docker-registry"` | no |
| docker\_secret\_namespace | The namespace where to create the docker-registry secret | `string` | `"default"` | no |
| docker\_server | Server location for Docker registry | `string` | `"https://index.docker.io/v1/"` | no |
| docker\_username | Username for Docker registry authentication | `string` | `"docker_username"` | no |
| enable\_irsa | Enable/disable IAM roles for Service Accounts | `bool` | `true` | no |
| encrypted\_boot\_volume | If true, an encrypted EKS AMI will be created to support encrypted boot volumes | `any` | n/a | yes |
| endpoint\_private\_access | Indicates whether or not the Amazon EKS private API server endpoint is enabled | `bool` | `false` | no |
| endpoint\_public\_access | Indicates whether or not the Amazon EKS public API server endpoint is enabled | `bool` | `true` | no |
| environment | The environment name | `string` | n/a | yes |
| generate\_kube\_config | Whether to generate a kubeconfig file or not | `bool` | `false` | no |
| helm\_releases | A composite map containing a set of key/value pairs needed for deploying Helm charts to the EKS cluster | <pre>map(object({<br>    repository           = string<br>    chart_name           = string<br>    chart_version        = string<br>    release_name         = string<br>    namespace            = string<br>    values               = list(string)<br>    set_values           = map(string)<br>    set_sensitive_values = map(string)<br>  }))</pre> | `{}` | no |
| iops | The amount of provisioned IOPS if volume type is io1 | `number` | `0` | no |
| k8s\_version | Desired Kubernetes master version. If you do not specify a value, the latest available version is used. | `string` | `""` | no |
| keypair\_name | The name of an existing key pair to access the K8S workers via SSH | `string` | `""` | no |
| kube\_config | Path to the kube config file to be used | `string` | `""` | no |
| lb\_target\_group | The App LB target group ARN we want this AutoScaling Group belongs to | `string` | `""` | no |
| map\_roles | A list of maps with the roles allowed to access EKS | <pre>list(object({<br>    role_arn = string<br>    username = string<br>    group    = string<br>  }))</pre> | `[]` | no |
| map\_users | A list of maps with the IAM users allowed to access EKS | <pre>list(object({<br>    user_arn = string<br>    username = string<br>    group    = string<br>  }))</pre> | `[]` | no |
| mixed\_workers\_configuration | A list of maps defining worker group configurations to be defined using AWS Launch Templates. | `any` | `[]` | no |
| private\_subnets\_ids | The IDs of at least two private subnets to deploy the K8S workers in | `list(string)` | n/a | yes |
| public\_subnets\_ids | The IDs of at least two public subnets for the K8S control plane ENIs | `list(string)` | n/a | yes |
| retention\_days | Specifies the number of days you want to retain log events in the specified log group. | `number` | `7` | no |
| ri\_worker\_configuration | A list of maps defining worker group configurations to be defined using AWS Launch Configurations. Meant to be used with RI. | `map(string)` | `{}` | no |
| tags | A list of additional maps of tags to add to the autoscaling group if using K8S autoscaler | `map(string)` | `{}` | no |
| threatstack\_key | The ThreatStack key to register the agent if running ThreatStack | `string` | `""` | no |
| update\_aws\_vpc\_cni | Set to true to update the AWS VPC CNI plugin to latest version (required to use IRSA for AWS VPC CNI pods) | `bool` | `false` | no |
| vpc\_cidr | The CIDR range used in the VPC | `any` | n/a | yes |
| vpc\_id | The ID of the VPC where we are deploying the EKS cluster | `any` | n/a | yes |
| worker\_role\_additional\_policies | List of IAM policies ARNs to attach to the workers role | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster\_arn | Shows kubernetes master's arn |
| cluster\_ca | Shows kubernetes cluster's certificate authority |
| cluster\_endpoint | Shows kubernetes master's endpoint |
| cluster\_name | The name of the EKS cluster |
| cluster\_oidc\_endpoint | The endpoint for IRSA/OIDC |
| encrypted\_ami\_id | Shows kubernetes cluster's encrypted ami id |
| oidc\_arn | Openid connect provider ARN |
| workers\_iam\_role\_arn | The k8s workers role arn |
| workers\_security\_group\_id | Shows kubernetes cluster's security group id |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module created by [Caylent](https://github.com/caylent).
