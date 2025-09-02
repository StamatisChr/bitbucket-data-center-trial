resource "random_pet" "hostname_suffix" {
  length = 2
}

##### EC2 instance #####
# create ec2 instance
resource "aws_instance" "docker_instance" {
  ami                  = data.aws_ami.ubuntu_2404.id
  instance_type        = var.tfe_instance_type
  key_name             = var.my_key_name # the key is region specific
  security_groups      = [aws_security_group.bitbucket_trial.name]
  iam_instance_profile = aws_iam_instance_profile.ssm_access.name

  user_data = templatefile("./templates/user_data_cloud_init.tftpl", {
    bbdc_hostname = "bbdc-${random_pet.hostname_suffix.id}.${var.hosted_zone_name}"

  })

  ebs_optimized = true
  root_block_device {
    volume_size = 120
    volume_type = "gp3"

  }

  tags = {
    Name        = "bbdc-${random_pet.hostname_suffix.id}"
    Environment = "stam-docker"
  }
}

resource "aws_eip" "bbdc_eip" {
  instance = aws_instance.docker_instance.id
}
#### EC2 security group ######

resource "aws_security_group" "bitbucket_trial" {
  name        = "bitbucket-trial"
  description = "Allow inbound traffic and outbound traffic for Bitbucket Trial"

  tags = {
    Name        = "bitbucket_trial"
    Environment = "stam-docker"
  }
}

resource "aws_vpc_security_group_ingress_rule" "port_7999_ssh" {
  security_group_id = aws_security_group.bitbucket_trial.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 7999
  ip_protocol       = "tcp"
  to_port           = 7999
}

resource "aws_vpc_security_group_ingress_rule" "port_7990_web" {
  security_group_id = aws_security_group.bitbucket_trial.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 7990
  ip_protocol       = "tcp"
  to_port           = 7990
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_traffic_ipv4" {
  security_group_id = aws_security_group.bitbucket_trial.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_route53_record" "dns_record" {
  zone_id = data.aws_route53_zone.my_aws_dns_zone.id
  name    = "bitbucket-${random_pet.hostname_suffix.id}.${var.hosted_zone_name}"
  type    = "A"
  ttl     = 120
  records = [aws_eip.bbdc_eip.public_ip]
}

resource "aws_iam_role" "ssm_access" {
  name = "ssm_access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Name = "stam-${random_pet.hostname_suffix.id}"
  }
}

resource "aws_iam_instance_profile" "ssm_access" {
  name = "ssm_access_profile"
  role = aws_iam_role.ssm_access.name
}

resource "aws_iam_role_policy_attachment" "SSM" {
  role       = aws_iam_role.ssm_access.name
  policy_arn = data.aws_iam_policy.SecurityComputeAccess.arn
}
