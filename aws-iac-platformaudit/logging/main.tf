provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

data "aws_organizations_organization" "current" {}

resource "random_uuid" "uuid1" {}
resource "random_uuid" "uuid2" {}

resource "aws_s3_bucket" "logging_bucket" {
  bucket = "${random_uuid.uuid1.result}"
  acl    = "private"
  versioning {
      enabled = "true"
  }
  logging {
    target_bucket = "${aws_s3_bucket.objectaccess_bucket.id}"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.kms_cloudtrail.key_id}"
        sse_algorithm = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket" "objectaccess_bucket" {
  bucket = "${random_uuid.uuid2.result}"
  acl    = "log-delivery-write"
  versioning {
      enabled = "true"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "logging_bpolicy" {
  bucket = "${aws_s3_bucket.logging_bucket.id}"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "CloudTrailPolicy",
    "Statement": [
        {
            "Sid": "BucketPermissionsCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${random_uuid.uuid1.result}"
        },
        {
            "Sid": "AllowCloudTrailLogDelivery",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": [
                "arn:aws:s3:::${random_uuid.uuid1.result}/*",
                "arn:aws:s3:::${random_uuid.uuid1.result}/AWSLogs/${data.aws_organizations_organization.current.id}/${data.aws_caller_identity.current.account_id}/*"
            ],
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_kms_key" "kms_cloudtrail" {
  description = "This key is used to encrypt CloudTrail logs"
  deletion_window_in_days = 10
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "key-default-1",
    "Statement": [
        {
            "Sid": "Allow administration of the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
                    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/matthew.lubbers@tdameritrade.com"
                ]
            },
            "Action": [
                "kms:Create*",
                "kms:Describe*",
                "kms:Enable*",
                "kms:List*",
                "kms:Put*",
                "kms:Update*",
                "kms:Revoke*",
                "kms:Disable*",
                "kms:Get*",
                "kms:Delete*",
                "kms:ScheduleKeyDeletion",
                "kms:CancelKeyDeletion"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow use of the key",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow local use of the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_kms_alias" "kms_cloudtrail_alias" {
  name          = "alias/aws_s3_kms_cloudtrail"
  target_key_id = "${aws_kms_key.kms_cloudtrail.key_id}"
}

output "cloudtrail_bucket_name" {
  value = "${aws_s3_bucket.logging_bucket.bucket}"
}