variable "region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "ssh_allowed_cidr" {
  description = "CIDR blocks that are allowed to access the instance via SSH"
  default     = "YOUR_PUBLIC_IP/32"  # Replace YOUR_PUBLIC_IP with your actual public IP
}

provider "aws" {
  region = var.region
  access_key = "AKIAIOSFODNN7EXAMPLE"
  secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
}

# Create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "Main VPC"
  }
}

# TODO: Evaluate if additional security configurations are needed for the VPC.

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "Private Subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "Main Internet Gateway"
  }
}

resource "aws_security_group" "ssh_security_group" {
  name        = "ssh_security_group"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SSH Access"
  }
}

resource "aws_iam_policy" "overly_broad_policy" {
  name        = "overly_broad_policy"
  description = "Policy that grants all privileges"

  policy = jsonencode(
    Version = "2012-10-17"
    Statement = [{
      Action = "*",
      Effect = "Allow",
      Resource = "*"
    }]
  })
}

# TODO: Critically review and restrict the AWS IAM 'aws_iam_policy.overly_broad_policy' as it currently grants full privileges.

resource "aws_elb" "example" {
  name               = "example-elb"
  availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 443
    lb_protocol       = "SSL"
    ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
  

  # Deliberately weak SSL/TLS configuration
  # TODO: Fix this to conform to strong SSL standards – avoid using SSL or TLS 1.0.
}

# Data source to get the latest AMI
data "aws_ami" "latest_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  owners = ["amazon"]
}
}