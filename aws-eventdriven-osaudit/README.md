# AWS Event-Driven OS Audit (aws-eventdriven-osaudit)

## Overview

Deploying this solution will generate a new Amazon Machine Image (AMI) which enables Syslog messages to be delivered to a CloudWatch Log Group for log ingestion per compute instance. Using an Event-Driven Architecture, newly provisioned compute instances will have Syslog enabled and forward per the aws-syslog.conf file. As part of the terraform template, IAM Roles, IAM Policies, Lambda functions, and CloudWatch Rules will be created to support the enablement of OS-level audit logging for the AWS platform.

NOTE: Log Delivery will only work if the compute instance is publicly routable. You can however create a VPC Endpoint to support log delivery.

## Prerequisites

* An AWS Account
* An AWS Publicly Routable VPC
* Packer
* Terraform

## Usage

Packer

1. Change directory to 'aws-eventdriven-osaudit/packer'
2. Define the appropriate variables within the 'template.json' file
* template.json
* * aws_access_key
* * aws_secret_key
* * region - AWS Region
* * vpc_id - ID of the VPC for Packer to use
* * subnet_id - ID of the VPCs Subnet
* * source_ami - Amazon Linux 2 has been tested
* * ssh_username - Amazon Linux 2 default username is 'ec2-user'
3. Use Packer to build a new AMI
```bash
packer build template.json
```
4. Once the build is complete, move onto the new section

Terraform

1. Change directory to 'aws-eventdriven-osaudit/terraform
2. Initialize the terraform template
```bash
terraform init
```
3. Apply the terraform template
```bash
terraform apply
```
4. Provide an AWS Region for the resources to be deployed to
5. For validation, create a new compute instance using the AMI generated from Packer. Once the instance is up and running, syslogs should be available inside of CloudWatch Logs

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