output "start_aws_ssm_session" {
  value = "aws ssm start-session --target ${aws_instance.docker_instance.id} --region ${var.aws_region}"
}

output "tfe-docker-fqdn" {
  description = "tfe-fqdn"
  value       = "http://bbdc-${random_pet.hostname_suffix.id}.${var.hosted_zone_name}:7990"

}