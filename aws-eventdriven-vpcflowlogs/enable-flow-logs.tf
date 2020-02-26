provider "aws" {
  region  = "${var.aws_region}"
}

variable "aws_region" {
  type = string
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_iam_role" "lambda_role" {
  name = "enable-flow-logs-lambda-${var.aws_region}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role" "invocation_role" {
  name = "enable-flow-logs-invoke-${var.aws_region}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role" "flowlogs_role" {
  name = "enable-flow-logs-role-${var.aws_region}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "CreateFlowLogs" {
  name = "CreateFlowLogs"
  role = "${aws_iam_role.lambda_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:CreateFlowLogs",
        "ec2:DescribeFlowLogs",
        "logs:CreateLogGroup",
        "logs:CreateLogDelivery",
        "logs:DeleteLogDelivery"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "iam:PassRole"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.flowlogs_role.id}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "PutLogs" {
  name = "PutLogs"
  role = "${aws_iam_role.lambda_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.enable_flowlogs_function.function_name}:*:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "LambdaInvocation" {
  name = "LambdaInvocation"
  role = "${aws_iam_role.invocation_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.enable_flowlogs_function.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "Enable_Flowlogs" {
  name = "EnableFlowLogs"
  role = "${aws_iam_role.flowlogs_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateFlowLogs",
        "logs:DescribeFlowLogs",
        "logs:CreateLogStream",
        "logs:CreateLogGroup",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/${data.aws_caller_identity.current.account_id}/${data.aws_region.current.name}/vpc/flowlogs:*:*"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "enable_flowlogs_function" {
  function_name = "enable-vpc-flow-logs-lf-${data.aws_region.current.name}"
  role          = "${aws_iam_role.lambda_role.arn}"
  handler       = "index.lambda_handler"
  runtime       = "python3.7"
  filename      = "./code/index.zip"
  timeout       = "10"
  environment {
    variables = {
      aws_accountid = "${data.aws_caller_identity.current.account_id}"
      stack_logrole = "${aws_iam_role.flowlogs_role.id}"
        }
    }
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowLambdaInvocationFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.enable_flowlogs_function.arn}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.enableflowlogs_rule.arn}"
}

resource "aws_cloudwatch_event_rule" "enableflowlogs_rule" {
  name        = "enable-vpc-flow-logs-er-${data.aws_region.current.name}"
  description = "Event rule to monitor ec2:CreateVpc"
  role_arn    = "${aws_iam_role.invocation_role.arn}"
  event_pattern = <<PATTERN
{
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "ec2.amazonaws.com"
    ],
    "eventName": [
      "CreateVpc"
    ],
    "awsRegion": [
      "${data.aws_region.current.name}"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "rule_target" {
  rule      = "${aws_cloudwatch_event_rule.enableflowlogs_rule.name}"
  arn       = "${aws_lambda_function.enable_flowlogs_function.arn}"
  depends_on  = [aws_cloudwatch_event_rule.enableflowlogs_rule]
}