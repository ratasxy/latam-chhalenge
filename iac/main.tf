terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
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
  function_name = "latam_lambda"
  role          = aws_iam_role.latam_role_lambda.arn
  handler       = "Latam.handler"

  source_code_hash = filebase64sha256("code.zip")

  runtime = "python3.8"
}