output "start_aws_ssm_session" {
  value = "aws ssm start-session --target ${aws_instance.docker_instance.id} --region ${var.aws_region}"
}

output "bitbucket-url" {
  description = "bitbucket-url"
  value       = "http://${aws_route53_record.dns_record.fqdn}:7990"
}