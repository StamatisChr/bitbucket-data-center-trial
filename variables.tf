variable "aws_region" {
  description = "The AWS region in use to spawn the resources"
  type        = string
}

variable "tfe_instance_type" {
  description = "The ec2 instance type for TFE"
  type        = string
  default     = "t3.xlarge"
}

variable "hosted_zone_name" {
  description = "The zone ID of my doormat hosted route53 zone"
  type        = string
}

variable "my_key_name" {
  description = "The name of the ssh key pair"
  type        = string
}

