# variables.tf

variable "region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.3.0/24"]
}

variable "private_subnet_cidr" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "container_image" {
  description = "Container image for ECS tasks"
  type        = string
  default     = "nginx:latest"
}

variable "desired_count" {
  description = "Number of ECS task instances"
  type        = number
  default     = 1
}

variable "ecs_cluster_name" {
  description = "ECS Cluster name"
  type        = string
  default     = "ecs-cluster"
}
