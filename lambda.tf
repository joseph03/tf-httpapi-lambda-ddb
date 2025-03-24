data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/package"
  output_path = "${path.module}/package.zip"
}

resource "aws_lambda_function" "http_api_lambda" {
  function_name    = "${local.name_prefix}-topmovies-api"
  description      = "Lambda function to write to dynamodb"
  runtime          = "python3.13"
  handler          = "app.lambda_handler"
  role             = aws_iam_role.lambda_exec.arn
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  
  # Enable AWS X-Ray tracing in Lambda
  /*
  tracing_config {
    mode = "Active"
  }
  */
  # end for X-ray

  environment {
    variables = {
      DDB_TABLE = aws_dynamodb_table.table.name
    }
  }

  depends_on = [ aws_cloudwatch_log_group.http_api ]
}

resource "aws_iam_role" "lambda_exec" {
  name = "${local.name_prefix}-topmovies-api-executionrole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}


// HEREDOC method to define policy. This does not allow 
// comments in between policy statements.
/*
resource "aws_iam_policy" "lambda_exec_role" {
  name = "${local.name_prefix}-topmovies-api-ddbaccess"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:DeleteItem",
                "dynamodb:Scan"
            ],
            "Resource": "${aws_dynamodb_table.table.arn}"
        },
        {   
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "xray:PutTraceSegments",
                "xray:PutTelemetryRecords"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}
*/

// json way to define policy. This allow comments
// within policy statements.
resource "aws_iam_policy" "lambda_exec_role" {
  name   = "${local.name_prefix}-topmovies-api-ddbaccess"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow DynamoDB actions
      {
        Effect   = "Allow"
        Action   = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.table.arn
      },
      # Allow CloudWatch Logs access
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      # Allow AWS X-Ray tracing
      {
        Effect   = "Allow"
        Action   = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_exec_role.arn
}

# added for lambda to use AWS x-ray
/*
resource "aws_iam_policy" "lambda_xray_policy" {
  name   = "${local.name_prefix}-topmovies-api-xray"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_xray_attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_xray_policy.arn
}
*/
