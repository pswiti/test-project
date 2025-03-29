variable "region" {
  description = "The AWS region to deploy the resources"
  type        = string
  default     = "us-west-2"
}

variable "image_uri" {
  description = "The URI of the Docker image in ECR"
  type        = string
}
