provider "aws" {
}

resource "aws_lambda_function" "java-example" {
  function_name = "ServerlessJavaExample"

  s3_bucket = var.s3_bucket
  s3_key    = "v2.0.0/java2.jar"

  handler = "io.pivopil.App"
  runtime = "java8"

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_java_lambda"

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

#######################
######### API Gataway
######################

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
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = "ANY"
  //  authorization = "NONE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.filing_authorizer.id
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.java-example.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_rest_api.example.root_resource_id
  http_method = "ANY"
  //  authorization = "NONE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.filing_authorizer.id
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.java-example.invoke_arn
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
  function_name = aws_lambda_function.java-example.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.example.execution_arn}/*/*"
}

##############
######### Custom Domain
##############

resource "aws_api_gateway_base_path_mapping" "custom_domain" {
  api_id      = aws_api_gateway_rest_api.example.id
  stage_name  = var.environment
  domain_name = aws_api_gateway_domain_name.example.domain_name
}


resource "aws_api_gateway_domain_name" "example" {
  domain_name     = "java.${var.public_subdomain}"
  certificate_arn = var.certificate_arn
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


#########################
#### Custom Authorizer
####   Authorization: super-secure-token
#########################

resource "aws_api_gateway_authorizer" "filing_authorizer" {
  name                             = "filingAuthorizer"
  type                             = "TOKEN"
  identity_source                  = "method.request.header.Authorization"
  rest_api_id                      = aws_api_gateway_rest_api.example.id
  authorizer_result_ttl_in_seconds = 0
  authorizer_uri = join("", [
    "arn:aws:apigateway:",
    data.aws_region.current.name,
    ":lambda:path/2015-03-31/functions/arn:aws:lambda:",
    data.aws_region.current.name,
    ":",
    data.aws_caller_identity.current.account_id,
    ":function:",
    var.custom_authorizer_function_name,
    "/invocations"
  ])
}


resource "aws_lambda_permission" "demo_auth_invocation_permissions" {
  action        = "lambda:InvokeFunction"
  function_name = var.custom_authorizer_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.example.execution_arn}/*/*"
}
