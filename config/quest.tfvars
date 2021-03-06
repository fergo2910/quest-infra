##### General
region = "us-east-1"

##### Networking
database_subnet_cidrs = ["172.30.16.0/23", "172.30.18.0/23", "172.30.20.0/23"]
private_subnet_cidrs  = ["172.30.10.0/23", "172.30.12.0/23", "172.30.14.0/23"]
public_subnet_cidrs   = ["172.30.0.0/23", "172.30.2.0/23", "172.30.4.0/23"]
vpc_cidr              = "172.30.0.0/16"
azs                   = ["us-east-1a", "us-east-1b", "us-east-1c"]
allow_inbound_traffic = [
  {
    protocol  = "tcp"
    from_port = 3000
    to_port   = 3000
    source    = "0.0.0.0/0"
  },
  {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
    source    = "0.0.0.0/0"
  },
  {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
    source    = "0.0.0.0/0"
  },
]
single_nat_gw = true #false for high availability

# EKS
cluster_name = "quest"

# All whitelisted IP's should be defined here. 
additional_public_access_cidrs = ["190.104.116.200/32"]

##### Route53
domain_name   = "quest.com"
create_domain = true