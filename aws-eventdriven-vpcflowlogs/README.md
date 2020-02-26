# AWS Event-Driven VPC Flow Logs

## Overview

Deploying this solution will enable VPC Flow Logs per the creation of any newly provisioned VPC within the solutions deployed region. This means that if the solution is deployed to us-east-1, only VPC's created in us-east-1 will be affected by the solution. As part of the template, a few IAM Roles, IAM Policies, a Lambda function, and a CloudWatch Rule will be created to support the enablement of VPC Flow Logs using an event-driven architecture.

## Prerequisites

* An AWS Account
* Terraform

## Usage

1. Change directory to 'aws-eventdriven-vpcflowlogs
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
