output "connect_to_ec2_via_ssh" {
  value       = "ssh ubuntu@bbdc-${random_pet.hostname_suffix.id}.${var.hosted_zone_name}"
}

output "tfe-docker-fqdn" {
  description = "tfe-fqdn"
  value       = "bbdc-${random_pet.hostname_suffix.id}.${var.hosted_zone_name}"

}