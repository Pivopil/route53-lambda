data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

data "aws_route53_zone" "public" {
  name         = var.public_subdomain
  private_zone = false
}
