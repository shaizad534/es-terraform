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
  subnet_id                   = var.pub-subnet
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
  vpc_id      = var.vpcid
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
