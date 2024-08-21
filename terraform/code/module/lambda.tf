# SNS Topic
resource "aws_sns_topic" "route53_topic" {
  name = "route53-topic"
}

# Route 53 Private Hosted Zone
resource "aws_route53_zone" "private_zone" {
  name = "local"
  vpc {
    vpc_id = aws_vpc.main.id
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# IAM Policy for Lambda
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  description = "IAM policy for Lambda to access SNS and Route 53"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sns:Publish"
        ]
        Effect   = "Allow"
        Resource = "${aws_sns_topic.route53_topic.arn}"
      },
      {
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_role.name
}

# Lambda Function
data "archive_file" "route53_zip" {
  type        = "zip"
  source_file = "../module/lambda/route53.py"
  output_path = "route53.zip"
}

resource "aws_lambda_function" "route53_lambda" {
  filename         = "route53.zip"
  function_name    = "route53_lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "route53.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.route53_zip.output_base64sha256

  environment {
    variables = {
      HOSTED_ZONE_ID = aws_route53_zone.private_zone.id
    }
  }
}

# Lambda Permission to allow SNS to invoke the Lambda function
resource "aws_lambda_permission" "sns_permission" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.route53_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.route53_topic.arn
}

resource "aws_sns_topic_subscription" "route53_topic" {
  topic_arn = aws_sns_topic.route53_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.route53_lambda.arn
}
