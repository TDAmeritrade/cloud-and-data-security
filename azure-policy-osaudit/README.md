# Azure Policy OS Audit & Monitoring (azure-policy-osaudit)

## Prerequisites

* An Existing Log Analytics Workspace
* Subscription-level Contributor
* Terraform

## Usage

1. Change directory to 'azure-policy-osaudit'
2. Initialize the terraform template
```bash
terraform init
```
3. Apply the terraform template
```bash
terraform apply
```
4. Provide the Name of the Log Analytics Workspace
5. Provide a location for the creation of a Managed Service Identity used for Policy remediation tasks
6. Provide the Name of the Resource Group where the Log Analytics Workspace resides
7. Provide the Subscription ID of where the Log Analytics Workspace resides

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