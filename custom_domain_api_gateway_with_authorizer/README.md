#Dependencies

##Deplou Authorizer
[Reused custom authorizer](https://github.com/Pivopil/terraform-aws-sls/lambda.tf)

## Deploy Stack with Certificate
[Reused certificate arn](../custom_domain_api_gateway_basic/main.tf)


##Get aws-lambda.jar from
[Reused Jar build from /target/aws-lambda.jar](https://github.com/Pivopil/aws-lambda-java)

##Upload to Lambda source bucket
```shell script
aws s3 cp aws-lambda.jar s3://terraform-serverless/v2.0.0/java2.jar --profile main-dev --region us-east-1
```

## Configure Terraform Provider
```
export AWS_PROFILE="training-aws"
export AWS_DEFAULT_REGION="us-east-1"
```
or change main.tf like this
```
provider "aws" {
  region  = "us-east-1"
  profile = "main-dev"
}
```

## Configure Terraform variables
```
export TF_VAR_certificate_arn="super-secure-token"
```
## Init
```
terraform init
```

## Plan
```
terraform plan
```

## Apply
```
terraform apply -auto-approve
```

## Destroy
```
terraform destroy -auto-approve
```

