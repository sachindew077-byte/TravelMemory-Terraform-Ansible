
variable "project_name" {
  description = "Name of the TravelMemory project"
  type        = string
  default     = "travelmemory"
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "key_pair_name" {
  description = "Existing AWS EC2 key pair name"
  type        = string
  default     = "travelmemory-key"
}
variable "existing_app_ami_id" {
  description = "AMI currently used by the existing TravelMemory EC2"
  type        = string
  default     = "ami-0fa5967347d08d2df"
}