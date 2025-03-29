provider "aws" {
  region = "us-west-2"  # Change to your preferred region
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

# Public Subnet 1
resource "aws_subnet" "public_subnet_1" {
  vpc_id                    = aws_vpc.main.id
  cidr_block                = "10.0.1.0/24"
  map_public_ip_on_launch   = true
  subnet_type               = "public"
}

# Public Subnet 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id                    = aws_vpc.main.id
  cidr_block                = "10.0.2.0/24"
  map_public_ip_on_launch   = true
  subnet_type               = "public"
}

# Private Subnet 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id                    = aws_vpc.main.id
  cidr_block                = "10.0.3.0/24"
  subnet_type               = "private"
}

# Private Subnet 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id                    = aws_vpc.main.id
  cidr_block                = "10.0.4.0/24"
  subnet_type               = "private"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name               = "lambda-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      }
    ]
  })
}

# Lambda Function (Container)
resource "aws_lambda_function" "lambda_function" {
  function_name = "my_lambda_function"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "nginx:latest"  # Using a container image
  image_uri     = "your_ecr_image_uri"  # Replace with your ECR image URI

  vpc_config {
    subnet_ids          = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_group_ids  = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      MY_ENV_VAR = "value"
    }
  }
}

# Security Group for Lambda
resource "aws_security_group" "lambda_sg" {
  vpc_id = aws_vpc.main.id
}

# API Gateway to Trigger Lambda
resource "aws_api_gateway_rest_api" "api" {
  name        = "LambdaAPI"
  description = "API Gateway for Lambda function"
}

resource "aws_api_gateway_resource" "root_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "myresource"
}

resource "aws_api_gateway_method" "api_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.root_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.root_resource.id
  http_method = aws_api_gateway_method.api_method.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri  = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda_function.arn}/invocations"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "prod"
}

resource "aws_lambda_permission" "allow_api_gateway" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
