########################################
# DATA SOURCES FOR NETWORK & SECURITY
########################################

locals {
  project_name  = "ofisy"
  name_prefix   = "ms-ofisy-${var.service}-db"
  database_name = "ms_ofisy_${var.service}_db"
}

# Busca a VPC da aplicação criada pela infraestrutura base/EKS
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${local.project_name}-vpc"]
  }
}

# Busca as subnets privadas da VPC
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${local.project_name}-private-subnet-*"]
  }
}

# Busca o Security Group da Lambda de autenticação para permitir tráfego no RDS.
data "aws_security_group" "lambda_auth" {
  count = var.allow_lambda_auth ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${local.project_name}-lambda-auth-sg"]
  }
}
