resource "random_pet" "hostname_suffix" {
  length = 2
}

##### EC2 instance #####
# create ec2 instance
resource "aws_instance" "docker_instance" {
  ami             = data.aws_ami.ubuntu_2404.id
  instance_type   = var.tfe_instance_type
  key_name        = var.my_key_name # the key is region specific
  security_groups = [aws_security_group.bbtest.name]

  user_data = templatefile("./templates/user_data_cloud_init.tftpl", {
    bbdc_hostname                  = "bbdc-${random_pet.hostname_suffix.id}.${var.hosted_zone_name}"
    
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

resource "aws_security_group" "bbtest" {
  name        = "bbtest"
  description = "Allow inbound traffic and outbound traffic for BBTest"

  tags = {
    Name        = "bbtest"
    Environment = "stam-docker"
  }
}

resource "aws_vpc_security_group_ingress_rule" "port_443_https" {
  security_group_id = aws_security_group.bbtest.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "port_80_http" {
  security_group_id = aws_security_group.bbtest.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "port_22_ssh" {
  security_group_id = aws_security_group.bbtest.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_traffic_ipv4" {
  security_group_id = aws_security_group.bbtest.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_route53_record" "tfe-a-record" {
  zone_id = data.aws_route53_zone.my_aws_dns_zone.id
  name    = "bbdc-${random_pet.hostname_suffix.id}.${var.hosted_zone_name}"
  type    = "A"
  ttl     = 120
  records = [aws_eip.bbdc_eip.public_ip]
}