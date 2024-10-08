//Provider Configuration
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.64.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

//IAM Role for Lambda Function
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

//IAM Policy for SQS and DynamoDB Access
resource "aws_iam_policy" "lambda_sqs_dynamodb_policy" {
  name        = "LambdaSQSDynamoDBAccessPolicy"
  description = "Policy allowing Lambda to access SQS and DynamoDB"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Resource = aws_dynamodb_table.my_table.arn
      },
      {
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = aws_sqs_queue.my_queue.arn
      }
    ]
  })
}

//DynamoDB Table
resource "aws_dynamodb_table" "my_table" {
  name           = "my-table"
  billing_mode    = "PAY_PER_REQUEST"
  hash_key        = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "my-table"
  }
}

//SQS Queue
resource "aws_sqs_queue" "my_queue" {
  name = "my-queue"
}

//Lambda Function
resource "aws_lambda_function" "my_lambda" {
  filename         = "lambda_function.zip"
  function_name    = "my_lambda_function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs16.x"
  source_code_hash = filebase64sha256("lambda_function.zip")  # Ensures Lambda updates when the code changes

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.my_table.name
    }
  }
}

//Lambda event source mapping
resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
  event_source_arn = aws_sqs_queue.my_queue.arn
  function_name    = aws_lambda_function.my_lambda.arn
  enabled          = true
}

//Attach Combined IAM Policy to Lambda Role
resource "aws_iam_role_policy_attachment" "lambda_sqs_dynamodb_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_sqs_dynamodb_policy.arn
}

//Attach AWSLambdaBasicExecutionRole
//Attaches the AWS-managed policy to allow Lambda to write logs to Amazon CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_basic_execution_role_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
