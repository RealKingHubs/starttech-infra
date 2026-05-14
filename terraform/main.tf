terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  #==========REMOTE BACKEND STATE CONFIGURATION===========

  backend "s3" {
    bucket         = "starttech-terraform-state-093796422475"
    key            = "global/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

#==========PROVIDERS===========
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "StartTech"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}


#===========NETWORKING MODULE===========
module "networking" {
  source = "./modules/networking"

  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}


#===========COMPUTE MODULE===========
module "compute" {
  source = "./modules/compute"

  environment            = var.environment
  vpc_id                 = module.networking.vpc_id
  public_subnets         = module.networking.public_subnets
  private_subnets        = module.networking.private_subnets
  alb_security_group     = module.networking.alb_security_group
  backend_security_group = module.networking.backend_security_group
}