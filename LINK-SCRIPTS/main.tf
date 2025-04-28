# Proveedor AWS
provider "aws" {
  region = "us-east-1"  
}

# VPC
resource "aws_vpc" "chatbot_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "chatbot-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "chatbot_igw" {
  vpc_id = aws_vpc.chatbot_vpc.id
  
  tags = {
    Name = "chatbot-igw"
  }
}

# Subnet pública
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.chatbot_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"  
  
  tags = {
    Name = "chatbot-public-subnet"
  }
}

# Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.chatbot_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.chatbot_igw.id
  }
  
  tags = {
    Name = "chatbot-public-rt"
  }
}

# Asociación de Route Table con subnet
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group para EC2
resource "aws_security_group" "ec2_sg" {
  name        = "chatbot-sg"
  description = "Security group for chatbot EC2"
  vpc_id      = aws_vpc.chatbot_vpc.id
  
  # Permitir SSH (para administración)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }
  
  # Permitir HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Permitir HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Permitir todo el tráfico de salida (crucial para actualizaciones y scripts)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "chatbot-sg"
  }
}

# Target Group para el ALB
resource "aws_lb_target_group" "chatbot_tg" {
  name     = "chatbot-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.chatbot_vpc.id
  
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Application Load Balancer
resource "aws_lb" "chatbot_alb" {
  name               = "chatbot-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet.id, aws_subnet.public_subnet2.id]  # Necesitas al menos 2 subnets en AZs diferentes
  
  enable_deletion_protection = false  # Para ambiente de desarrollo
  
  tags = {
    Name = "chatbot-alb"
  }
}

# Segunda subnet pública (requerida para ALB)
resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.chatbot_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"  # Diferente AZ que la primera subnet
  
  tags = {
    Name = "chatbot-public-subnet2"
  }
}

# Asociación subnet2 con route table pública
resource "aws_route_table_association" "public_rta2" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group para ALB
resource "aws_security_group" "alb_sg" {
  name        = "chatbot-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.chatbot_vpc.id
  
  # Permitir HTTP desde internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Permitir HTTPS desde internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Permitir todo el tráfico de salida
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "chatbot-alb-sg"
  }
}

# ALB Listener HTTP (redirección a HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.chatbot_alb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type = "redirect"
    
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ALB Listener HTTPS
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.chatbot_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.cert_validation.certificate_arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chatbot_tg.arn
  }
}

# Registro de la instancia EC2 en el Target Group
resource "aws_lb_target_group_attachment" "ec2_attach" {
  target_group_arn = aws_lb_target_group.chatbot_tg.arn
  target_id        = aws_instance.chatbot_ec2.id
  port             = 80
}