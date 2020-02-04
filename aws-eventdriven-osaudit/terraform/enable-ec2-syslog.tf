provider "aws" {
  region  = "us-east-1"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_iam_role" "lambda_role" {
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

resource "aws_iam_role_policy" "CreateEC2Syslog" {
  name = "CreateEC2Syslog"
  role = "${aws_iam_role.lambda_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:AssociateIamInstanceProfile"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "iam:PassRole"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.ec2syslog_role.id}"
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
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.enable_ec2_syslog_function.function_name}:*:*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "invocation_role" {
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
      "Resource": "${aws_lambda_function.enable_ec2_syslog_function.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role" "ec2syslog_role" {
  name = "Syslog"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ec2syslog_profile" {
  name = "ec2syslog"
  role = "${aws_iam_role.ec2syslog_role.name}"
}

resource "aws_iam_role_policy" "Enable_EC2Syslog" {
  name = "syslog-to-cloudwatch"
  role = "${aws_iam_role.ec2syslog_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/${data.aws_caller_identity.current.account_id}/${data.aws_region.current.name}/ec2/syslog:*:*"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "enable_ec2_syslog_function" {
  function_name = "Enable-EC2Syslog"
  role          = "${aws_iam_role.lambda_role.arn}"
  handler       = "index.lambdaHandler"
  runtime       = "python3.7"
  filename      = "./code/index.zip"
  timeout       = "120"
  environment {
    variables = {
      aws_accountid = "${data.aws_caller_identity.current.account_id}"
      syslogip = "${aws_iam_instance_profile.ec2syslog_profile.name}"
        }
    }
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.enable_ec2_syslog_function.arn}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.enableec2syslog_rule.arn}"
}

resource "aws_cloudwatch_event_rule" "enableec2syslog_rule" {
  name        = "Enable-EC2Syslog"
  description = "Attach EC2 IAM Role per new Instance startup via lambda for Syslog"
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
      "RunInstances",
      "StartInstances",
      "RebootInstances"
    ],
    "awsRegion": [
      "${data.aws_region.current.name}"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "rule_target" {
  rule      = "${aws_cloudwatch_event_rule.enableec2syslog_rule.name}"
  arn       = "${aws_lambda_function.enable_ec2_syslog_function.arn}"
  depends_on  = [aws_cloudwatch_event_rule.enableec2syslog_rule]
}