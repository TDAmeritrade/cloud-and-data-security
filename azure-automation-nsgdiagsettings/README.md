# Azure Automation NSG Flow Logs & Resource Logs

## Prerequisites

* An Existing Log Analytics Workspace
* An Existing Automation Account (with Azure Run As Account)
* An Existing Storage Account
* Subscription-level Contributor
* Terraform

## Usage

1. Change directory to 'azure-automation-nsgdiagsettings'
2. Initialize the terraform template
```bash
terraform init
```
4. Change each PowerShell scripts variables to the appropriate values
* enableDiagnosticSettings.ps1
* * $logAnalyticsWorkspaceName - Name of the Log Analytics Workspace
* * $logAnalyticsResourceGroupName - Resource Group of the Log Analytics Workspace
* * $logAnalyticsSubscriptionId - Subscription ID of the Log Analytics Workspace
* enableNsgFlowLogs.ps1
* * $logAnalyticsWorkspaceName - Name of the Log Analytics Workspace
* * $logAnalyticsResourceGroupName - Resource Group of the Log Analytics Workspace
* * $logAnalyticsSubscriptionId - Subscription ID of the Log Analytics Workspace
* * $storageAccountResourceGroupName - Resource Group of the Storage Accounts
* * $storageAccountSubscriptionId - Subscription ID of the Storage Accounts
* * $storageAccountRegions - Create a key-value mapping between the NSG & Storage Accounts regions.
5. Apply the terraform template
```bash
terraform apply
```
6. Provide the Name of the Automation Account
7. Provide the Resource Group Name of where the Automation Account resides

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