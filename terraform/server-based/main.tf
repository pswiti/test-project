# main.tf

provider "aws" {
  region = var.region
}

# Create VPC with 1 Public and 1 Private Subnet
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "ecs-vpc"
  cidr = var.vpc_cidr

  azs             = ["us-east-1a"]  # Only use 1 AZ for simplicity
  private_subnets = var.private_subnet_cidr
  public_subnets  = var.public_subnet_cidr
  enable_nat_gateway = true
  single_nat_gateway = true
}

# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name
}

# ALB Security Group (allows HTTP traffic)
resource "aws_security_group" "alb_sg" {
  name_prefix = "alb-sg-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer (ALB) in Public Subnets
resource "aws_lb" "ecs_alb" {
  name               = "ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets
  enable_deletion_protection = false
}

# Target Group for ECS Service (to associate with Load Balancer)
resource "aws_lb_target_group" "ecs_target_group" {
  name     = "ecs-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}

# Listener for ALB (HTTP port 80)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      status_code = 200
      content_type = "text/plain"
      message_body = "Service is up!"
    }
  }
}

# ECS Task Definition (example container)
resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "ecs-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  
  container_definitions = jsonencode([{
    name      = "example-container"
    image     = var.container_image  # Use the container image from variables
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}

# ECS Service to run task in Private Subnets
resource "aws_ecs_service" "ecs_service" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups = [aws_security_group.alb_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = "example-container"
    container_port   = 80
  }
}
