# Variables TF File

variable "region" {
  description = "AWS Region"
  default     = "eu-central-1"
}

variable "instancetype" {
  description = "Instance Type to be used for Instance"
  default     = "t2.micro"
}

variable "ami_name" {
  description = "AMI name to be used for the instance."
  default     = "amzn2-ami-hvm-2.0.20210126.0-x86_64-gp2"
}

variable "HostIp" {
  description = " Host IP to be allowed SSH for"
  default     = "202.65.147.137/32"
}

variable "PvtIp" {
  description = " Host IP to be allowed SSH for"
  default     = "10.126.12.0/24"
}

variable "AppName" {
  description = "Application Name"
  default     = "Elastic search"
}

variable "Env" {
  description = "Application Name"
  default     = "Dev"
}

variable "pub_availability_zone" {
  description = "availability zone used for the demo, based on region"
  default     = "eu-central-1a"
}

variable "pri_availability_zone" {
  description = "availability zone used for the demo, based on region"
  default     = "eu-central-1b"
}

variable "vpc_name" {
  description = "VPC for building demos"
  default     = "demo-vpc"
}

variable "vpc_cidr_block" {
  description = "IP addressing for demo Network"
  default     = "10.126.0.0/16"
}

variable "vpc_public_subnet_1_cidr" {
  description = "Public 0.0 CIDR for externally accessible subnet"
  default     = "10.126.1.0/24"
}

variable "vpc_private_subnet_1_cidr" {
  description = "Private CIDR for internally accessible subnet"
  default     = "10.126.12.0/24"
}
