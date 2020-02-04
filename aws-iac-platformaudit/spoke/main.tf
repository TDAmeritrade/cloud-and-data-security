provider "aws" {
  region = "us-east-1"
}

variable "s3_bucket_name" {
  type = string
  description = "The S3 bucket name created from applying the logging Terraform template"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_organizations_organization" "current" {}

resource "random_uuid" "uuid1" {}

resource "aws_cloudwatch_log_group" "cloudtrail_loggroup" {
  name = "/aws/${data.aws_caller_identity.current.account_id}/${data.aws_region.current.name}/cloudtrail"
  retention_in_days = 90
}

resource "aws_iam_role" "cloudtrail_role" {
  name = "CloudTrail"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudtrail_rpolicy" {
    name = "cloudtrail_iam_policy"
    role = "${aws_iam_role.cloudtrail_role.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailCreateLogStream",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream"
      ],
      "Resource": [
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail_loggroup.name}:log-stream:*",
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail_loggroup.name}:log-stream:${data.aws_organizations_organization.current.id}_*"
      ]
    },
    {
      "Sid": "AWSCloudTrailPutLogEvents",
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail_loggroup.name}:log-stream:*",
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail_loggroup.name}:log-stream:${data.aws_organizations_organization.current.id}_*"
      ]
    }
  ]
}
EOF
}

resource "aws_cloudtrail" "cloudtrail_trail" {
  name = "${random_uuid.uuid1.result}"
  s3_bucket_name = "${var.s3_bucket_name}"
  include_global_service_events = "true"
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail_loggroup.arn}"
  cloud_watch_logs_role_arn = "${aws_iam_role.cloudtrail_role.arn}"
  is_multi_region_trail = "true"
  is_organization_trail = "true"
  enable_log_file_validation = "true"
  event_selector {
    read_write_type           = "All"
    include_management_events = "true"
    data_resource {
      type = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
    data_resource {
      type = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }
}

resource "aws_iam_role_policy" "cloudtrail_role_policy" {
    name = "cloudtrail_iam_policy"
    role = "${aws_iam_role.cloudtrail_role.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailCreateLogStream",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream"
      ],
      "Resource": [
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail_loggroup.name}:log-stream:*",
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail_loggroup.name}:log-stream:${data.aws_organizations_organization.current.id}_*"
      ]
    },
    {
      "Sid": "AWSCloudTrailPutLogEvents",
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail_loggroup.name}:log-stream:*",
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail_loggroup.name}:log-stream:${data.aws_organizations_organization.current.id}_*"
      ]
    }
  ]
}
EOF
}