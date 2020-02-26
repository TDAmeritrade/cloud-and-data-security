provider "azurerm" {
    features {}
}

variable "automation_account_name" {
  type = string
  description = "Name of the Automation Account"
}

variable "automation_account_rsg" {
  type = string
  description = "Resource Group Name of the Automation Account"
}

data "local_file" "enableDiagSettings" {
  filename = "enableDiagnosticSettings.ps1"
}

data "local_file" "enableNsgFlowLogs" {
  filename = "enableNsgFlowLogs.ps1"
}

data "azurerm_automation_account" "automation_account" {
  name                = "${var.automation_account_name}"
  resource_group_name = "${var.automation_account_rsg}"
}

data "azurerm_resource_group" "automation_rsg" {
  name = "${var.automation_account_rsg}"
}

resource "azurerm_automation_runbook" "automation_runbook_diag" {
  name                    = "enableDiagSettings"
  location                = "${data.azurerm_resource_group.automation_rsg.location}"
  resource_group_name     = "${data.azurerm_automation_account.automation_account.resource_group_name}"
  automation_account_name = "${data.azurerm_automation_account.automation_account.name}"
  log_verbose             = "true"
  log_progress            = "true"
  description             = "This runbook automates the enablement of diagnostic settings per Azure resource"
  runbook_type            = "PowerShell"

  publish_content_link {
    uri = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/c4935ffb69246a6058eb24f54640f53f69d3ac9f/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
  }

  content = "${data.local_file.enableDiagSettings.content}"
}

resource "azurerm_automation_runbook" "automation_runbook_nsg" {
  name                    = "enableNsgFlowLogs"
  location                = "${data.azurerm_resource_group.automation_rsg.location}"
  resource_group_name     = "${data.azurerm_automation_account.automation_account.resource_group_name}"
  automation_account_name = "${data.azurerm_automation_account.automation_account.name}"
  log_verbose             = "true"
  log_progress            = "true"
  description             = "This runbook automates the enablement of NSG flow logs per NSG and storage account region"
  runbook_type            = "PowerShell"

  publish_content_link {
    uri = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/c4935ffb69246a6058eb24f54640f53f69d3ac9f/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
  }

  content = "${data.local_file.enableNsgFlowLogs.content}"
}

resource "azurerm_automation_schedule" "automation_schedule" {
  name                    = "${data.azurerm_automation_account.automation_account.name}-schedule"
  resource_group_name     = "${data.azurerm_automation_account.automation_account.resource_group_name}"
  automation_account_name = "${data.azurerm_automation_account.automation_account.name}"
  frequency               = "hour"
  interval                = 1
  timezone                = "Central Standard Time"
}

resource "azurerm_automation_job_schedule" "automation_job_diag" {
  resource_group_name     = "${data.azurerm_automation_account.automation_account.resource_group_name}"
  automation_account_name = "${data.azurerm_automation_account.automation_account.name}"
  schedule_name           = "${azurerm_automation_schedule.automation_schedule.name}"
  runbook_name            = "${azurerm_automation_runbook.automation_runbook_diag.name}"
}

resource "azurerm_automation_job_schedule" "automation_job_nsg" {
  resource_group_name     = "${data.azurerm_automation_account.automation_account.resource_group_name}"
  automation_account_name = "${data.azurerm_automation_account.automation_account.name}"
  schedule_name           = "${azurerm_automation_schedule.automation_schedule.name}"
  runbook_name            = "${azurerm_automation_runbook.automation_runbook_nsg.name}"
}

resource "azurerm_automation_module" "az_accounts" {
  name                    = "Az.Accounts"
  resource_group_name     = "${data.azurerm_automation_account.automation_account.resource_group_name}"
  automation_account_name = "${data.azurerm_automation_account.automation_account.name}"
  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Accounts/1.7.2"
  }
}

resource "azurerm_automation_module" "az_storage" {
  name                    = "Az.Storage"
  resource_group_name     = "${data.azurerm_automation_account.automation_account.resource_group_name}"
  automation_account_name = "${data.azurerm_automation_account.automation_account.name}"
  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Storage/1.12.0"
  }

  depends_on = [azurerm_automation_module.az_accounts]
}

resource "azurerm_automation_module" "az_resources" {
  name                    = "Az.Resources"
  resource_group_name     = "${data.azurerm_automation_account.automation_account.resource_group_name}"
  automation_account_name = "${data.azurerm_automation_account.automation_account.name}"
  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Resources/1.11.0"
  }

  depends_on = [azurerm_automation_module.az_storage]
}

resource "azurerm_automation_module" "az_opinsights" {
  name                    = "Az.OperationalInsights"
  resource_group_name     = "${data.azurerm_automation_account.automation_account.resource_group_name}"
  automation_account_name = "${data.azurerm_automation_account.automation_account.name}"
  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.OperationalInsights/1.3.4"
  }

  depends_on = [azurerm_automation_module.az_resources]
}

resource "azurerm_automation_module" "az_automation" {
  name                    = "Az.Automation"
  resource_group_name     = "${data.azurerm_automation_account.automation_account.resource_group_name}"
  automation_account_name = "${data.azurerm_automation_account.automation_account.name}"
  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Automation/1.3.6"
  }

  depends_on = [azurerm_automation_module.az_opinsights]
}

resource "azurerm_automation_module" "az_monitor" {
  name                    = "Az.Monitor"
  resource_group_name     = "${data.azurerm_automation_account.automation_account.resource_group_name}"
  automation_account_name = "${data.azurerm_automation_account.automation_account.name}"
  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Monitor/1.6.0"
  }

  depends_on = [azurerm_automation_module.az_automation]
}

resource "azurerm_automation_module" "az_network" {
  name                    = "Az.Network"
  resource_group_name     = "${data.azurerm_automation_account.automation_account.resource_group_name}"
  automation_account_name = "${data.azurerm_automation_account.automation_account.name}"
  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Network/2.3.1"
  }

  depends_on = [azurerm_automation_module.az_monitor]
}

