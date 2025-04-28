# main.tf

# Configuración del proveedor AWS
provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "Región de AWS para el despliegue"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR para la VPC"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Zonas de disponibilidad"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "db_name" {
  description = "Nombre de la base de datos"
  default     = "wordpress"
}

variable "db_username" {
  description = "Usuario de la base de datos"
  default     = "admin"
}

variable "db_password" {
  description = "Contraseña de la base de datos"
  sensitive   = true
}

variable "domain_name" {
  description = "Nombre de dominio para WordPress"
  default     = "example.com"
}

# VPC y subredes
resource "aws_vpc" "wordpress_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "wordpress-vpc"
  }
}

# Subredes públicas
resource "aws_subnet" "public_subnets" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.wordpress_vpc.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "wordpress-public-subnet-${count.index + 1}"
  }
}

# Subredes privadas
resource "aws_subnet" "private_subnets" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.wordpress_vpc.id
  cidr_block              = "10.0.${count.index + 101}.0/24"
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false
  
  tags = {
    Name = "wordpress-private-subnet-${count.index + 1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.wordpress_vpc.id
  
  tags = {
    Name = "wordpress-igw"
  }
}

# Elastic IPs para los NAT Gateways
resource "aws_eip" "nat_eip" {
  count      = length(var.availability_zones)
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
  
  tags = {
    Name = "wordpress-nat-eip-${count.index + 1}"
  }
}

# NAT Gateways
resource "aws_nat_gateway" "nat_gateway" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id
  depends_on    = [aws_internet_gateway.igw]
  
  tags = {
    Name = "wordpress-nat-gateway-${count.index + 1}"
  }
}

# Tabla de rutas pública
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.wordpress_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "wordpress-public-rt"
  }
}

# Asociación de tabla de rutas pública
resource "aws_route_table_association" "public_rta" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Tablas de rutas privadas
resource "aws_route_table" "private_route_table" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.wordpress_vpc.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
  }
  
  tags = {
    Name = "wordpress-private-rt-${count.index + 1}"
  }
}

# Asociación de tablas de rutas privadas
resource "aws_route_table_association" "private_rta" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

# Grupos de seguridad
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg-wordpress"
  description = "Security Group for ALB"
  vpc_id      = aws_vpc.wordpress_vpc.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "alb-sg-wordpress"
  }
}

resource "aws_security_group" "webserver_sg" {
  name        = "webserver-sg-wordpress"
  description = "Security Group for WordPress servers"
  vpc_id      = aws_vpc.wordpress_vpc.id
  
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]  # Se recomienda restringir esto a IPs específicas en producción
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "webserver-sg-wordpress"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg-wordpress"
  description = "Security Group for RDS"
  vpc_id      = aws_vpc.wordpress_vpc.id
  
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.webserver_sg.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "rds-sg-wordpress"
  }
}

resource "aws_security_group" "efs_sg" {
  name        = "efs-sg-wordpress"
  description = "Security Group for EFS"
  vpc_id      = aws_vpc.wordpress_vpc.id
  
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.webserver_sg.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "efs-sg-wordpress"
  }
}

# EFS para almacenamiento compartido
resource "aws_efs_file_system" "wordpress_efs" {
  creation_token = "wordpress-efs"
  encrypted      = true
  
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  
  tags = {
    Name = "wordpress-efs"
  }
}

resource "aws_efs_mount_target" "efs_mount" {
  count           = length(var.availability_zones)
  file_system_id  = aws_efs_file_system.wordpress_efs.id
  subnet_id       = aws_subnet.private_subnets[count.index].id
  security_groups = [aws_security_group.efs_sg.id]
}

# Grupo de subredes para RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "wordpress-rds-subnet-group"
  subnet_ids = aws_subnet.private_subnets[*].id
  
  tags = {
    Name = "wordpress-rds-subnet-group"
  }
}

# Base de datos RDS Multi-AZ
resource "aws_db_instance" "wordpress_db" {
  identifier             = "wordpress-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  multi_az               = true
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  backup_retention_period = 7
  
  tags = {
    Name = "wordpress-db"
  }
}

# Certificado SSL para el ALB
resource "aws_acm_certificate" "wordpress_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name = "wordpress-certificate"
  }
}

# Target Group para el ALB
resource "aws_lb_target_group" "wordpress_tg" {
  name     = "wordpress-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.wordpress_vpc.id
  
  health_check {
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }
  
  tags = {
    Name = "wordpress-target-group"
  }
}

# Application Load Balancer
resource "aws_lb" "wordpress_alb" {
  name               = "wordpress-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public_subnets[*].id
  
  enable_deletion_protection = false
  
  tags = {
    Name = "wordpress-alb"
  }
}

# HTTP Listener para el ALB
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.wordpress_alb.arn
  port              = 80
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

# HTTPS Listener para el ALB
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.wordpress_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.wordpress_cert.arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress_tg.arn
  }
}

# Script de inicio para instancias EC2
data "template_file" "user_data" {
  template = <<-EOF
    #!/bin/bash
    # Actualizar el sistema
    apt-get update -y
    apt-get upgrade -y
    
    # Instalar paquetes necesarios
    apt-get install -y apache2 php php-mysql php-gd php-curl php-mbstring php-xml php-imagick php-zip php-json libapache2-mod-php nfs-common
    
    # Instalar la CLI de AWS (opcional)
    apt-get install -y awscli
    
    # Obtener metadatos de la instancia para el nombre de host
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    HOSTNAME="wordpress-$INSTANCE_ID"
    hostnamectl set-hostname "$HOSTNAME"
    
    # Crear directorio para EFS
    mkdir -p /var/www/html/wp-content
    
    # Montar EFS para contenido compartido
    EFS_DNS="${aws_efs_file_system.wordpress_efs.dns_name}"
    mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 "$EFS_DNS":/ /var/www/html/wp-content
    
    # Añadir entrada en fstab para montaje automático
    echo "$EFS_DNS:/ /var/www/html/wp-content nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0" >> /etc/fstab
    
    # Descargar WordPress
    cd /tmp
    wget https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz
    cp -a /tmp/wordpress/. /var/www/html/
    rm -rf /tmp/wordpress /tmp/latest.tar.gz
    
    # Configurar WordPress
    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
    
    # Reemplazar valores en wp-config.php
    DB_NAME="${var.db_name}"
    DB_USER="${var.db_username}"
    DB_PASSWORD="${var.db_password}"
    DB_HOST="${aws_db_instance.wordpress_db.endpoint}"
    
    sed -i "s/database_name_here/$DB_NAME/" /var/www/html/wp-config.php
    sed -i "s/username_here/$DB_USER/" /var/www/html/wp-config.php
    sed -i "s/password_here/$DB_PASSWORD/" /var/www/html/wp-config.php
    sed -i "s/localhost/$DB_HOST/" /var/www/html/wp-config.php
    
    # Generar claves únicas para seguridad
    SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    STRING='put your unique phrase here'
    printf '%s\n' "g/$STRING/d" a "$SALT" . w | ed -s /var/www/html/wp-config.php
    
    # Configurar permisos
    chown -R www-data:www-data /var/www/html/
    chmod -R 755 /var/www/html/
    
    # Reiniciar Apache
    systemctl restart apache2
  EOF
}

# Launch Template para Auto Scaling
resource "aws_launch_template" "wordpress_lt" {
  name_prefix            = "wordpress-lt-"
  image_id               = "ami-0c7217cdde317cfec"  # Ubuntu 20.04 LTS en us-east-1, actualizar según región
  instance_type          = "t2.micro"
  key_name               = "your-key-pair-name"  # Reemplazar con tu nombre de key pair
  
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]
  
  user_data = base64encode(data.template_file.user_data.rendered)
  
  iam_instance_profile {
    name = aws_iam_instance_profile.wordpress_profile.name
  }
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "wordpress-instance"
    }
  }
}

# IAM Role y Profile para las instancias EC2
resource "aws_iam_role" "wordpress_role" {
  name = "wordpress-ec2-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.wordpress_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "wordpress_profile" {
  name = "wordpress-instance-profile"
  role = aws_iam_role.wordpress_role.name
}

# Auto Scaling Group
resource "aws_autoscaling_group" "wordpress_asg" {
  name                = "wordpress-asg"
  vpc_zone_identifier = aws_subnet.private_subnets[*].id
  desired_capacity    = 2
  min_size            = 2
  max_size            = 4
  
  launch_template {
    id      = aws_launch_template.wordpress_lt.id
    version = "$Latest"
  }
  
  target_group_arns = [aws_lb_target_group.wordpress_tg.arn]
  
  health_check_type         = "ELB"
  health_check_grace_period = 300
  
  tag {
    key                 = "Name"
    value               = "wordpress-asg-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Políticas de Auto Scaling
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "wordpress-scale-up"
  autoscaling_group_name = aws_autoscaling_group.wordpress_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "wordpress-scale-down"
  autoscaling_group_name = aws_autoscaling_group.wordpress_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

# CloudWatch Alarmas para Auto Scaling
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "wordpress-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.wordpress_asg.name
  }
  
  alarm_description = "Scale up if CPU > 80% for 15 minutes"
  alarm_actions     = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "wordpress-low-cpu"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 20
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.wordpress_asg.name
  }
  
  alarm_description = "Scale down if CPU < 20% for 15 minutes"
  alarm_actions     = [aws_autoscaling_policy.scale_down.arn]
}

# Alarma para errores del Load Balancer
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "wordpress-error-rate"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  
  dimensions = {
    LoadBalancer = aws_lb.wordpress_alb.arn_suffix
    TargetGroup  = aws_lb_target_group.wordpress_tg.arn_suffix
  }
  
  alarm_description = "Alert if 5XX errors > 10 in 15 minutes"
}

# Bucket S3 para backups
resource "aws_s3_bucket" "backup_bucket" {
  bucket = "wordpress-backup-${random_string.bucket_suffix.result}"
  
  tags = {
    Name = "wordpress-backup-bucket"
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_acl" "backup_bucket_acl" {
  bucket = aws_s3_bucket.backup_bucket.id
  acl    = "private"
}

# Outputs
output "alb_dns_name" {
  value       = aws_lb.wordpress_alb.dns_name
  description = "DNS name of the Application Load Balancer"
}

output "db_endpoint" {
  value       = aws_db_instance.wordpress_db.endpoint
  description = "Endpoint of the RDS instance"
}

output "efs_dns_name" {
  value       = aws_efs_file_system.wordpress_efs.dns_name
  description = "DNS name of the EFS file system"
}

output "backup_bucket_name" {
  value       = aws_s3_bucket.backup_bucket.bucket
  description = "Name of the S3 bucket for backups"
}