terraform {
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.92.0"
    }
  }
}

locals {
  name = "${var.prefix_name}-${var.base_name}"
  port = 6962
}

module "storage" {
  source = "../../storage"

  prefix_name = var.prefix_name
  base_name   = var.base_name
  region      = var.region
  ephemeral   = var.ephemeral
}

module "secretsmanager" {
  source = "../../secretsmanager"

  base_name                                  = var.base_name
  region                                     = var.region
  tls_private_key_ecdsa_p256_public_key_pem  = module.insecuretlskey.tls_private_key_ecdsa_p256_public_key_pem
  tls_private_key_ecdsa_p256_private_key_pem = module.insecuretlskey.tls_private_key_ecdsa_p256_private_key_pem
}

# [WARNING]
# This module will store unencrypted private keys in the Terraform state file.
# DO NOT use this for production logs.
module "insecuretlskey" {
  source = "../../insecuretlskey"
}

# ECS cluster
# This will be used to run the conformance and hammer binaries on Fargate.
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${local.name}"
}

resource "aws_ecs_cluster_capacity_providers" "ecs_capacity" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = ["FARGATE"]
}

## Virtual private cloud
# This will be used for the containers to communicate between themselves, and
# the S3 bucket.
resource "aws_default_vpc" "default" {
   tags = {
    Name = "Default VPC"
  }
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}