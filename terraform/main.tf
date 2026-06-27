terraform {
  required_version = ">= 1.11.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
resource "aws_vpc" "startuptech_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "startuptech-vpc"
  }
}

# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.startuptech_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "startuptech-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.startuptech_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "startuptech-public-subnet-2"
  }
}
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.startuptech_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "startuptech-private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.startuptech_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "startuptech-private-subnet-2"
  }
}
# Internet Gateway
resource "aws_internet_gateway" "startuptech_igw" {
  vpc_id = aws_vpc.startuptech_vpc.id

  tags = {
    Name = "startuptech-IGW"
  }
}
# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  depends_on = [
    aws_internet_gateway.startuptech_igw
  ]

  tags = {
    Name = "startuptech-NAT-EIP"
  }
}
# NAT Gateway
resource "aws_nat_gateway" "startuptech_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  depends_on = [
    aws_internet_gateway.startuptech_igw
  ]

  tags = {
    Name = "startuptech-NAT-Gateway"
  }
}
# Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.startuptech_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.startuptech_igw.id
  }

  tags = {
    Name = "startuptech-Public-Route-Table"
  }
}
# Private Route Table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.startuptech_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.startuptech_nat_gateway.id
  }

  tags = {
    Name = "startuptech-Private-Route-Table"
  }
}
# Public Subnet 1 Association
resource "aws_route_table_association" "startuptech_public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

# Public Subnet 2 Association
resource "aws_route_table_association" "startuptech_public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

# Private Subnet 1 Association
resource "aws_route_table_association" "startuptech_private_subnet_1_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

# Private Subnet 2 Association
resource "aws_route_table_association" "startuptech_private_subnet_2_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}
# Bastion Host Security Group
resource "aws_security_group" "bastion_sg" {
  name        = "startuptech-Bastion-SG"
  description = "Allow SSH access"
  vpc_id      = aws_vpc.startuptech_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["102.209.29.210/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "startuptech-Bastion-SG"
  }
}
# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "startuptech-ALB-SG"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.startuptech_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "startuptech-ALB-SG"
  }
}
# Backend Security Group
resource "aws_security_group" "backend_sg" {
  name        = "startuptech-Backend-SG"
  description = "Allow traffic from ALB and Bastion"
  vpc_id      = aws_vpc.startuptech_vpc.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "startuptech-Backend-SG"
  }
}
# MongoDB Security Group
resource "aws_security_group" "mongodb_sg" {
  name        = "startuptech-MongoDB-SG"
  description = "Allow MongoDB access from Backend"
  vpc_id      = aws_vpc.startuptech_vpc.id

  ingress {
    description     = "MongoDB from Backend"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "startuptech-MongoDB-SG"
  }
}
# Bastion Host
resource "aws_instance" "bastion_host" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet_1.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  key_name                    = "startuptech-ec2-key"

  tags = {
    Name = "startuptech-Bastion-Host"
  }
}
# Allocate an Elastic IP for the Bastion
resource "aws_eip" "bastion_eip" {
  domain = "vpc"

  tags = {
    Name = "startuptech-Bastion-EIP"
  }
}
# Associate the Elastic IP
resource "aws_eip_association" "bastion_eip_assoc" {
  instance_id   = aws_instance.bastion_host.id
  allocation_id = aws_eip.bastion_eip.id
}

# Backend EC2 Instance
resource "aws_instance" "backend_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_subnet_1.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  key_name               = "startuptech-ec2-key"

  user_data = file("${path.module}/user_data/backend_setup.sh")

  tags = {
    Name = "startuptech-Backend-Server"
  }
}

# MongoDB EC2 Instance
resource "aws_instance" "mongodb_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_subnet_2.id
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]
  key_name               = "startuptech-ec2-key"

  user_data = file("${path.module}/user_data/mongodb_setup.sh")

  tags = {
    Name = "startuptech-MongoDB-Server"
  }
}
# Application Load Balancer (ALB)
resource "aws_lb" "startuptech_alb" {
  name               = "startuptech-alb-v2"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb_sg.id
  ]

  subnets = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

  tags = {
    Name = "startuptech-ALB"
  }
}
# Target Group
resource "aws_lb_target_group" "backend_tg" {
  name     = "startuptech-backend-tg-v2"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.startuptech_vpc.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "startuptech-Backend-TG"
  }
}
# Backend EC2
resource "aws_lb_target_group_attachment" "backend_attachment" {
  target_group_arn = aws_lb_target_group.backend_tg.arn
  target_id        = aws_instance.backend_server.id
  port             = 8080
}
# Listener
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.startuptech_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

