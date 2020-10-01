##Upload to Lambda source bucket
```shell script
nano main.js
zip example.zip main.js
aws s3 cp example.zip s3://terraform-serverless/v1.0.0/example.zip --profile main-dev --region us-east-1

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
