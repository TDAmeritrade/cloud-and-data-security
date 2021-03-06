# Cloud & Data Security
RSAC 2020 - The Fog of Cloud Security Logging

## Prerequisites

* Packer
* Terraform

## Installation

For Windows:

```powershell
choco install packer -y
choco install terraform -y
```

For Mac OS:

```bash
brew install packer
brew install terraform
```

## Usage

Each solution is separated by directory.

AWS Solutions
* AWS Infrastructure-as-Code Platform Audit (aws-iac-platformaudit)
* AWS Event-Driven VPC Flow Logs (aws-eventdriven-vpcflowlogs)
* AWS Event-Driven OS Audit (aws-eventdriven-osaudit)

Azure Solutions
* Azure Automation NSG Flow Logs & Resource Logs (azure-automation-nsgdiagsettings)
* Azure Policy OS Audit & Monitoring (azure-policy-osaudit)

A single readme file will be located inside of each directory which provides step-by-step instructions to deploy each solution.

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