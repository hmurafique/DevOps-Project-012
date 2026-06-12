variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins server"
  type        = string
  default     = "t2.medium"
}

variable "key_name" {
  description = "AWS key pair name"
  type        = string
  default     = "jenkins-server-keypair"
}

variable "ami_id" {
  description = "AMI ID for Jenkins server (Amazon Linux 2)"
  type        = string
  default     = "ami-0c02fb55956c7d316"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_name" {
  description = "Name tag for Jenkins server"
  type        = string
  default     = "Jenkins-Server"
}
