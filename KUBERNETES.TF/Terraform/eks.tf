# Configuración del proveedor AWS
provider "aws" {
  region = "us-east-1"
}

# Datos del AWS Account ID
data "aws_caller_identity" "current" {}

# Datos de la VPC por defecto
data "aws_vpc" "default" {
  default = true
}

# Datos de las subredes públicas en la VPC por defecto
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b"]
  }
}

# Obtener subredes específicas por zona de disponibilidad
data "aws_subnet" "public_1a" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-1a"]
  }
  depends_on = [data.aws_subnets.public]
}

data "aws_subnet" "public_1b" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-1b"]
  }
  depends_on = [data.aws_subnets.public]
}

# Datos del rol IAM Lab
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Cluster EKS
resource "aws_eks_cluster" "academy_cluster" {
  name     = "academy-cluster-002"
  role_arn = data.aws_iam_role.lab_role.arn

  vpc_config {
    subnet_ids = [
      data.aws_subnet.public_1a.id,
      data.aws_subnet.public_1b.id
    ]
    endpoint_private_access = false
    endpoint_public_access  = true
  }

  depends_on = [
    data.aws_subnet.public_1a,
    data.aws_subnet.public_1b
  ]
}


# Outputs
output "cluster_endpoint" {
  description = "Endpoint del cluster EKS"
  value       = aws_eks_cluster.academy_cluster.endpoint
}

output "cluster_name" {
  description = "Nombre del cluster EKS"
  value       = aws_eks_cluster.academy_cluster.name
}

output "subnet_1a_id" {
  description = "ID de la subred en us-east-1a"
  value       = data.aws_subnet.public_1a.id
}

output "subnet_1b_id" {
  description = "ID de la subred en us-east-1b"
  value       = data.aws_subnet.public_1b.id
}