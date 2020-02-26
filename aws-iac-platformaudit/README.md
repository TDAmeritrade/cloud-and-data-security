# AWS Infrastructure-as-Code Platform Audit (aws-iac-platformaudit)

## Overview

Deploying this solution will enable platform-level auditing within the executed AWS account for all regions using CloudTrail. As part of the 'logging' template, two private S3 bucket with their appropriate S3 bucket policies are created along with the enablement of S3 bucket encryption using AWS KMS. As part of the 'spoke' template, the previously created S3 bucket will be provided to CloudTrail for log storage. Using an IAM Role and IAM Policy, the CloudTrail service is able to publish CloudTrail logs to the provided S3 bucket.

If you are expriencing issues with deploying the 'logging' KMS key policy, change the 'user/terraform' to any user who needs key management priviledges and re-deploy.

## Prerequisites

* An AWS Account
* Terraform

## Usage

1. Change directory to 'aws-iac-platformaudit/logging'
2. Initialize the terraform template
```bash
terraform init
```
3. Apply the terraform template
```bash
terraform apply
```
4. Provide an AWS Region for the resources to be deployed to

For each AWS account, follow these steps:

1. Change directory to 'aws-iac-platformaudit/spoke'
2. Initialize the terraform template
```bash
terraform init
```
3. Apply the terraform template
```bash
terraform apply
```
4. Provide an AWS Region for the resources to be deployed to


NOTE: These solutions are purely for demonstrational purposes and should be customized for your organization for any production deployments

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

MIT License

Copyright (c) [2020] [TD Ameritrade]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.