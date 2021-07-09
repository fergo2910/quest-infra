# ---------------------------------------------------------------------------------------------------------------------
# AWS Route53 hosted zone resources
# ---------------------------------------------------------------------------------------------------------------------

## Route53 hosted zone for a regular domain
resource "aws_route53_zone" "domain" {
  count    = var.create_hosted_zone && !var.private_zone ? 1 : 0
  provider = aws.domain
  name     = var.domain_name

  tags = {
    "Name" = "${var.domain_name}-hosted-zone"
  }

  force_destroy = false
}

resource "aws_route53_zone" "private_domain" {
  count    = var.create_hosted_zone && var.private_zone ? 1 : 0
  provider = aws.domain
  name     = var.domain_name

  vpc {
    vpc_id = var.private_zone ? var.vpc_id : ""
  }

  tags = {
    "Name" = "${var.domain_name}-hosted-zone"
  }

  force_destroy = false
}
