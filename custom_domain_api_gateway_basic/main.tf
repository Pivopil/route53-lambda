provider "aws" {
}

module "acm" {
  source             = "terraform-aws-modules/acm/aws"
  version            = "2.11.0"
  create_certificate = true
  domain_name        = var.public_subdomain
  zone_id            = data.aws_route53_zone.public.zone_id
  subject_alternative_names = [
    var.public_subdomain,
    "java.${var.public_subdomain}",
    "api.${var.public_subdomain}",
    "*.${var.public_subdomain}"
  ]
  tags = {
    Name = var.public_subdomain
  }
}

resource "aws_lambda_function" "example" {
  function_name = "ServerlessExample"

  s3_bucket = var.s3_bucket
  s3_key    = "v1.0.0/example.zip"

  handler = "main.handler"
  runtime = "nodejs10.x"

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_example_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_api_gateway_rest_api" "example" {
  name        = "ServerlessExample"
  description = "Terraform Serverless Application Example"
  //  endpoint_configuration {
  //    types = ["REGIONAL"]
  //  }
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  parent_id   = aws_api_gateway_rest_api.example.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.example.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.example.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.example.id
  resource_id   = aws_api_gateway_rest_api.example.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.example.invoke_arn
}

resource "aws_api_gateway_deployment" "example" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]
  description = "Updated at ${timestamp()}"
  rest_api_id = aws_api_gateway_rest_api.example.id
  stage_name  = var.environment
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.example.execution_arn}/*/*"
}

resource "aws_api_gateway_base_path_mapping" "custom_domain" {
  api_id      = aws_api_gateway_rest_api.example.id
  stage_name  = var.environment
  domain_name = aws_api_gateway_domain_name.example.domain_name
}

resource "aws_api_gateway_domain_name" "example" {
  domain_name     = "api.${var.public_subdomain}"
  certificate_arn = module.acm.this_acm_certificate_arn
  //  endpoint_configuration {
  //    types = ["REGIONAL"]
  //  }
}

resource "aws_route53_record" "region_one" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = aws_api_gateway_domain_name.example.domain_name
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.example.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.example.cloudfront_zone_id
    evaluate_target_health = true
  }
}

