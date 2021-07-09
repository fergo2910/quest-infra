variable "region" {
  description = "The AWS region we wish to provision in, by default"
  default     = "us-east-1"
}

variable "create_hosted_zone" {
  description = "Boolean that controls if whether to create a host zone or not"
  default     = true
}

variable "domain_name" {
  description = "The domain name for which we are creating a hosted zone."
}

variable "environment" {
  description = "The name of the environment we are creating this hosted zone for."
  default     = ""
}

variable "vpc_id" {
  description = "The Id of the VPC that our private zone will be attached to"
  default     = ""
}

variable "private_zone" {
  description = "Bool to determine whether this zone is private or not, if private you need to provide the vpc_id"
  default     = false
}

variable "tags" {
  description = "A map of tags for the Route53 resources"
  type        = map(any)
  default     = {}
}
