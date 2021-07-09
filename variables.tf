variable "region" {
  description = "aws region"
  default     = "us-east-1"
  type        = string
}

variable "environment" {
  description = "environment based on terraform workspace"
  default     = ""
  type        = string
}

# networking
variable "vpc_cidr" {
  description = "Main Network CIDR"
  default     = ""
  type        = string
}
variable "azs" {
  type = list(string)
}
variable "public_subnet_cidrs" {
  type = list(string)
}
variable "private_subnet_cidrs" {
  type = list(string)
}
variable "database_subnet_cidrs" {
  type = list(string)
}
variable "allow_inbound_traffic" {
  type = list(object({
    protocol  = string,
    from_port = number,
    to_port   = number,
    source    = string,
  }))
}
variable "single_nat_gw" {
  description = "If true, all private and database subnets will share 1 Route Table and NAT GW.  If false, one NAT-gw per AZ will be created along with one RT per AZ."
  default     = true
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  default     = "application"
  type        = string
}

variable "additional_public_access_cidrs" {
  type    = list(string)
  default = []
}

##### Route53
variable "domain_name" {
  description = "A domain name to use in the account"
  type        = string
}
variable "create_domain" {
  description = "If a domain should be created"
  type        = bool
  default     = false
}