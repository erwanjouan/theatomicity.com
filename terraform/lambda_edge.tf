resource "aws_lambda_function" "edge" {
  provider         = aws.cloudfront
  function_name    = var.lambda_file_name
  filename         = "${path.module}/../lambda/${var.lambda_file_name}.zip"
  handler          = "${var.lambda_file_name}.handler"
  role             = aws_iam_role.lambda_execution.arn
  runtime          = "nodejs10.x"
  publish          = true
  source_code_hash = base64sha256(filebase64("${path.module}/../lambda/${var.lambda_file_name}.zip"))

}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role" "lambda_execution" {
  name_prefix        = "lambda-execution-role-"
  description        = "Managed by Terraform"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "edgelambda.amazonaws.com",
          "lambda.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}