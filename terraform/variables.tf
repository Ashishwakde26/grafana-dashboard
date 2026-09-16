variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the new public subnet"
  type        = string
  default     = "10.0.10.0/24" # Change if this overlaps with existing subnets
}

variable "availability_zone" {
  description = "AZ for the public subnet (leave empty to pick the first available)"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "Existing EC2 Key Pair name for SSH"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.xlarge"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 60
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this!
}

variable "allowed_monitoring_cidrs" {
  description = "CIDR blocks allowed to access Grafana/Prometheus"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this!
}

variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
  default     = "kind-monitoring"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  default     = "SuperSecurePass123!"
  sensitive   = true
}