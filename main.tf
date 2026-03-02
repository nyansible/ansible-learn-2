terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    ansible = {
      source  = "ansible/ansible"
      version = "~> 1.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file(var.ssh_public_key_path)
}

resource "aws_security_group" "instance_sg" {
  name        = "ubuntu-instance-sg"
  description = "Allow SSH inbound and all outbound"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "WireGuard VPN"
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ubuntu-instance-sg"
  }
}

resource "aws_instance" "ubuntu" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "ubuntu-server"
  }
}

resource "ansible_host" "ubuntu" {
  name   = aws_instance.ubuntu.public_ip
  groups = ["webservers", "vpn"]

  variables = {
    wireguard_addresses   = jsonencode(["10.8.0.2/24"])
    wireguard_endpoint    = aws_instance.ubuntu.public_ip
    wireguard_port        = "51820"
    wireguard_mtu         = "1492"
    wireguard_allowed_ips = "0.0.0.0/0, ::/0"
  }
}
