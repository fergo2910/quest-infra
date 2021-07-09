output "zone_id" {
  value = var.private_zone ? aws_route53_zone.private_domain[0].zone_id : aws_route53_zone.domain[0].zone_id
}

output "name_servers" {
  value = concat(aws_route53_zone.domain.*.name_servers, aws_route53_zone.private_domain.*.name_servers)
}

output "domain_name" {
  value = var.domain_name
}
