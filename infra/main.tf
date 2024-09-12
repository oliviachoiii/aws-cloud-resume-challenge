resource "aws_lambda_function" "view_lambda" {
    filename = data.archive_file.zip_func.output_path
    function_name = "view_lambda"
    role = aws_iam_role.iam_for_lambda.arn
    handler = "lambda_func.lambda_handler"
    runtime = "python3.8"
    source_code_hash = data.archive_file.zip_func.output_base64sha256
}

# Archive a file to be used with Lambda using consistent file mode
data "archive_file" "zip_func" {
  type             = "zip"
  source_file      = "${path.module}/lambda/lambda_func.py"
  output_file_mode = "0666"
  output_path      = "${path.module}/lambda/lambda_func.zip"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_policy" "iam_policy_for_website" {
  name        = "iam_policy_for_website"
  path        = "/"
  description = "AWS IAM Policy for managing the project role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "dynamodb:UpdateItem",
		  "dynamodb:GetItem",
          "dynamodb:PutItem",
        ]
        Effect   = "Allow"
        Resource : "arn:aws:dynamodb:*:*:table/cloudresume-table"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "attach_iam" {
  name = "attatch_iam"
  roles = [aws_iam_role.iam_for_lambda.name]
  policy_arn = aws_iam_policy.iam_policy_for_website.arn
}

resource "aws_lambda_function_url" "lambda_url" {
  function_name = aws_lambda_function.view_lambda.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["https://oliviachoidev.com"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 3600 # Cache the CORS preflight request for 1 hour (3600 seconds)
  }
}
