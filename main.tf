# Create key using awscli 
# aws ec2 create-key-pair --key-name shaz-tst --query 'KeyMaterial' --output text >shaz-tst.pem
# 

#terraform {
#  backend "s3" {
#    bucket = "state-tf-poc"
#    key    = "mini-tf/terraform.tfstate"
#    region = "eu-central-1"
#  }
#}

# Setup our aws provider
provider "aws" {
  region = var.region
}

# Define a vpc
resource "aws_vpc" "vpc_name" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = var.vpc_name
  }
}

# Internet gateway for the public subnet
resource "aws_internet_gateway" "demo_ig" {
  vpc_id = aws_vpc.vpc_name.id
  tags = {
    Name = "demo_ig"
  }
}

# Create Eip for NAT Gateway
resource "aws_eip" "nat-gw-eip" {
  vpc = true
}

# Nat gateway for the private subnet
resource "aws_nat_gateway" "demo_ngw" {
  allocation_id = aws_eip.nat-gw-eip.id
  subnet_id     = aws_subnet.vpc_public_sn.id

  tags = {
    Name = "demo-ngw"
  }
}

# Public subnet
resource "aws_subnet" "vpc_public_sn" {
  vpc_id            = aws_vpc.vpc_name.id
  cidr_block        = var.vpc_public_subnet_1_cidr
  availability_zone = var.pub_availability_zone
  tags = {
    Name = "vpc_public_sn"
  }
}

# Private subnet
resource "aws_subnet" "vpc_private_sn" {
  vpc_id            = aws_vpc.vpc_name.id
  cidr_block        = var.vpc_private_subnet_1_cidr
  availability_zone = var.pub_availability_zone
  tags = {
    Name = "vpc_private_sn"
  }
}

# Routing table for public subnet
resource "aws_route_table" "vpc_public_sn_rt" {
  vpc_id = aws_vpc.vpc_name.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_ig.id
  }
  tags = {
    Name = "vpc_public_sn_rt"
  }
}

# Associate the routing table to public subnet
resource "aws_route_table_association" "vpc_public_sn_rt_assn" {
  subnet_id      = aws_subnet.vpc_public_sn.id
  route_table_id = aws_route_table.vpc_public_sn_rt.id
}

# Routing table for private subnet
resource "aws_route_table" "vpc_private_sn_rt" {
  vpc_id = aws_vpc.vpc_name.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.demo_ngw.id
  }
  tags = {
    Name = "vpc_private_sn_rt"
  }
}

# Associate the routing table to public subnet
resource "aws_route_table_association" "vpc_private_sn_rt_assn" {
  subnet_id      = aws_subnet.vpc_private_sn.id
  route_table_id = aws_route_table.vpc_private_sn_rt.id
}


# SSH access and a key-pair to access the instance
# Generate new private key

resource "tls_private_key" "my_key" {
  algorithm = "RSA"
}

# Generate a key-pair with above key

resource "aws_key_pair" "deployer" {
  key_name   = "my-es-key"
  public_key = tls_private_key.my_key.public_key_openssh
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.ami_name]
  }
}

#  Elastic-Search Ec2 resource
resource "aws_instance" "elastic-search" {
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = var.instancetype
  key_name                    = aws_key_pair.deployer.key_name
  subnet_id                   = aws_subnet.vpc_public_sn.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.elastic-search.id]

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = tls_private_key.my_key.private_key_pem

  }

  provisioner "remote-exec" {

    inline = [
      #Script used to set up a new node inside an Elasticsearch cluster in AWS
      "sudo yum update -y",

      # Importing ES-GPG key
      "sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch",

      # Java 11 Installation
      "sudo amazon-linux-extras install java-openjdk11 -y",

      # Elasticsearch 7.13.0 Installation
      "sudo wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.13.0-x86_64.rpm",
      "sudo rpm --install elasticsearch-7.13.0-x86_64.rpm",

      # Shortest configuration for Elasticsearch nodes to find each other
      "sudo su -c\"echo 'cluster.name: my-es-cluster' >> /etc/elasticsearch/elasticsearch.yml\"",
      "sudo su -c\"echo 'network.host: 0.0.0.0' >> /etc/elasticsearch/elasticsearch.yml\"",
      "sudo su -c\"echo 'discovery.seed_hosts: ${aws_instance.elastic-search.private_ip}' >> /etc/elasticsearch/elasticsearch.yml\"",
      "sudo su -c\"echo 'xpack.security.enabled : true' >> /etc/elasticsearch/elasticsearch.yml\"",
      "sudo su -c\"echo 'cluster.initial_master_nodes:  ${aws_instance.elastic-search.private_ip}' >> /etc/elasticsearch/elasticsearch.yml\"",

      ### Executing systemctl commands
      "sudo systemctl daemon-reload",
      "sudo systemctl enable elasticsearch",
      "sudo systemctl start elasticsearch",
      "echo 'Node setup finished!' > ~/terraform.txt"
    ]

  }

  tags = {
    Name = var.AppName
    Env  = var.Env
  }

  lifecycle {
    create_before_destroy = true
  }

}

# Adding Security Group for our Instance :
resource "aws_security_group" "elastic-search" {
  name        = "elastic-search-sg"
  description = "Elastic Search Security Group"
  vpc_id      = aws_vpc.vpc_name.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9300
    to_port     = 9300
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}
