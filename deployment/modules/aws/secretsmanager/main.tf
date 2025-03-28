terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.92.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# Secrets Manager

# ECDSA key with P256 elliptic curve. Do NOT use this in production environment.
#
# Security Notice
# The private key generated by this resource will be stored unencrypted in your 
# Terraform state file. Use of this resource for production deployments is not 
# recommended.
#
# See https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key.
resource "tls_private_key" "sctfe_ecdsa_p256" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "aws_secretsmanager_secret" "sctfe_ecdsa_p256_public_key" {
  name = "${var.base_name}-ecdsa-p256-public-key"

  tags = {
    label = "tesseract-public-key"
  }
}

resource "aws_secretsmanager_secret_version" "sctfe_ecdsa_p256_public_key" {
  secret_id = aws_secretsmanager_secret.sctfe_ecdsa_p256_public_key.id
  secret_string = tls_private_key.sctfe_ecdsa_p256.public_key_pem
}

resource "aws_secretsmanager_secret" "sctfe_ecdsa_p256_private_key" {
  name = "${var.base_name}-ecdsa-p256-private-key"

  tags = {
    label = "tesseract-private-key"
  }
}

resource "aws_secretsmanager_secret_version" "sctfe_ecdsa_p256_private_key" {
  secret_id = aws_secretsmanager_secret.sctfe_ecdsa_p256_private_key.id
  secret_string = tls_private_key.sctfe_ecdsa_p256.private_key_pem
}
