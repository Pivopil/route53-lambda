variable "public_subdomain" {
  default = "test.com"
}

variable "s3_bucket" {
  default = "terraform-serverless"
}

variable "environment" {
  default = "dev"
}

variable "certificate_arn" {
}

variable "custom_authorizer_function_name" {
  default = "custom_authorizer"
}
