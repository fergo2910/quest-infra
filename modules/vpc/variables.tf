# -------------------------------------------------------------
# Network variables
# -------------------------------------------------------------

variable "region" {
  description = "The AWS region we wish to provision in, by default"
  default     = "us-east-1"
}

variable "environment" {
  description = "Name of the environment (terraform.workspace or static environment name for vpcs not managed with a workspace)"
  default     = ""
}

variable "vpc_cidr" {
  description = "The CIDR range for the VPC"
}

variable "enable_dns_support" {
  description = "True if the DNS support is enabled in the VPC"
  default     = true
}

variable "enable_dns_hostnames" {
  description = "True if DNS hostnames is enabled in the VPC"
  default     = true
}

variable "instance_tenancy" {
  description = "The type of tenancy for EC2 instances launched into the VPC"
  default     = "default"
}

variable "map_to_public_ip" {
  description = "True if public IPs are assigned to instances launched in a subnet"
  default     = true
}

variable "azs" {
  description = "A list of Availability Zones to use in a specific Region"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "A list of the CIDR ranges to use for public subnets"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "A list of the CIDR ranges to use for private subnets"
  type        = list(string)
  default     = []
}

variable "db_subnet_cidrs" {
  description = "A list of the CIDR ranges for database subnets"
  type        = list(string)
  default     = []
}

variable "enable_nat_gw" {
  description = "True if we want to create at least one NAT-gw for private subnets"
  default     = true
}

variable "single_nat_gw" {
  description = "If true, all private and database subnets will share 1 Route Table and NAT GW.  If false, one NAT-gw per AZ will be created along with one RT per AZ."
  default     = true
}

variable "enable_igw" {
  description = "True if you want an igw added to your public route table"
  default     = true
}

# -------------------------------------------------------------
# Security variables
# -------------------------------------------------------------
variable "icmp_diagnostics_enable" {
  description = "Enable full icmp for diagnostic purposes"
  default     = false
}

variable "enable_nacls" {
  description = "Enable creation of restricted-by-default network acls."
  default     = true
}

variable "allow_inbound_traffic_default_public_subnet" {
  description = "A list of maps of inbound traffic allowed by default for public subnets"
  type = list(object({
    protocol  = string
    from_port = number
    to_port   = number
    source    = string
  }))

  default = [
    {
      # ephemeral tcp ports (allow return traffic for software updates to work)
      protocol  = "tcp"
      from_port = 1024
      to_port   = 65535
      source    = "0.0.0.0/0"
    },
    {
      # ephemeral udp ports (allow return traffic for software updates to work)
      protocol  = "udp"
      from_port = 1024
      to_port   = 65535
      source    = "0.0.0.0/0"
    },
  ]
}

variable "allow_inbound_traffic_public_subnet" {
  description = "The inbound traffic the customer needs to allow for public subnets"
  type = list(object({
    protocol  = string
    from_port = number
    to_port   = number
    source    = string
  }))
  default = []
}

variable "allow_inbound_traffic_default_private_subnet" {
  description = "A list of maps of inbound traffic allowed by default for private subnets"
  type = list(object({
    protocol  = string
    from_port = number
    to_port   = number
    source    = string
  }))

  default = [
    {
      # ephemeral tcp ports (allow return traffic for software updates to work)
      protocol  = "tcp"
      from_port = 1024
      to_port   = 65535
      source    = "0.0.0.0/0"
    },
    {
      # ephemeral udp ports (allow return traffic for software updates to work)
      protocol  = "udp"
      from_port = 1024
      to_port   = 65535
      source    = "0.0.0.0/0"
    },
  ]
}

variable "allow_inbound_traffic_private_subnet" {
  description = "The ingress traffic the customer needs to allow for private subnets"
  type = list(object({
    protocol  = string
    from_port = number
    to_port   = number
    source    = string
  }))
  default = []
}

variable "allow_external_principals" {
  description = "Allow external principals to access the RAM Share for Transit Gateway?"
  default     = false
}

# -------------------------------------------------------------
# Tagging
# -------------------------------------------------------------

variable "tags" {
  description = "A map of tags for the VPC resources"
  type        = map(string)
  default     = {}
}

variable "eks_network_tags" {
  description = "A map of tags needed by EKS to identify the VPC and subnets"
  type        = map(string)
  default     = {}
}

variable "eks_private_subnet_tags" {
  description = "A map of tags needed by EKS to identify private subnets for internal LBs"
  type        = map(string)
  default     = {}
}

variable "eks_public_subnet_tags" {
  description = "A map of tags needed by EKS to identify public subnets for public LBs"
  type        = map(string)
  default     = {}
}
