terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"

  backend "s3" {
    region = "us-east-1"
    bucket = "terraform-latam-jsantillana"
    key = "terraform.tfstate"
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "latam_role_lambda" {
  name = "latam_role_lambda"

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

resource "aws_lambda_function" "latam_lambda" {
  filename      = "code.zip"
  layers = ["arn:aws:lambda:us-east-1:446751924810:layer:python-3-7-scikit-learn-0-23-1:2"]

  function_name = "latam_lambda"
  role          = aws_iam_role.latam_role_lambda.arn
  handler       = "Latam.handler"

  source_code_hash = filebase64sha256("code.zip")

  runtime = "python3.7"
}

resource "aws_api_gateway_rest_api" "latam-api-gateway" {
  name        = "LatamApi"
  description = "Latam Api Gateway"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.latam-api-gateway.id
  parent_id   = aws_api_gateway_rest_api.latam-api-gateway.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.latam-api-gateway.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration-lambda" {
  rest_api_id = aws_api_gateway_rest_api.latam-api-gateway.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.latam_lambda.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.latam-api-gateway.id
  resource_id   = aws_api_gateway_rest_api.latam-api-gateway.root_resource_id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.latam-api-gateway.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.latam_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "example" {
  depends_on = [
    aws_api_gateway_integration.integration-lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.latam-api-gateway.id
  stage_name  = "dev"
}

resource "aws_lambda_permission" "apigw-permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.latam_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.latam-api-gateway.execution_arn}/*/*"
}