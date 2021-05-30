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

variable "pub-subnet" {
  description = "subnet id to be used for the instance."
  default     = "subnet-012faa821f1360416"
}

variable "vpcid" {
  description = "Vpc to be used for the instance."
  default     = "vpc-03bff28e963f1392d"
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

