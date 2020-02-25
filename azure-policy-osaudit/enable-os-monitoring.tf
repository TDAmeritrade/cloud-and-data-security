provider "azurerm" {
    features {}
}

resource "random_uuid" "uuid1" {}

resource "random_uuid" "uuid2" {}

variable "subscriptionId" {
  type = string
  description = "Azure Subscription Id of Log Analytics Workspace"
}

variable "resourceGroup" {
  type = string
  description = "Azure Resource Group of Log Analytics Workspace"
}

variable "msiLocation" {
  type = string
  description = "Location of MSI for Policy Assignment"
}

variable "logAnalyticsWorkspace" {
  type = string
  description = "Log Analytics Workspace Name"
}

data "azurerm_subscription" "current" {}

resource "azurerm_role_definition" "lac_role" {
  name        = "Log Agent Contributor"
  scope       = "${data.azurerm_subscription.current.id}"
  description = "This is a custom role created via Terraform"

  permissions {
    actions     = [ "*/read",
                    "Microsoft.Automation/automationAccounts/*",
                    "Microsoft.ClassicCompute/virtualMachines/extensions/*",
                    "Microsoft.ClassicStorage/storageAccounts/listKeys/action",
                    "Microsoft.Compute/virtualMachines/extensions/*",
                    "Microsoft.Insights/alertRules/*",
                    "Microsoft.Insights/diagnosticSettings/*",
                    "Microsoft.OperationalInsights/*",
                    "Microsoft.OperationsManagement/*",
                    "Microsoft.Resources/deployments/*",
                    "Microsoft.Resources/subscriptions/resourcegroups/deployments/*",
                    "Microsoft.Storage/storageAccounts/listKeys/action",
                    "Microsoft.Support/*" ]
  }

  assignable_scopes = [
    "${data.azurerm_subscription.current.id}",
  ]
}

resource "azurerm_role_definition" "cac_role" {
  name        = "Compute Agent Contributor"
  scope       = "${data.azurerm_subscription.current.id}"
  description = "This is a custom role created via Terraform"

  permissions {
    actions     = [ "Microsoft.Authorization/*/read",
                    "Microsoft.Compute/availabilitySets/*",
                    "Microsoft.Compute/locations/*",
                    "Microsoft.Compute/virtualMachines/*",
                    "Microsoft.Compute/virtualMachineScaleSets/*",
                    "Microsoft.Compute/disks/write",
                    "Microsoft.Compute/disks/read",
                    "Microsoft.Compute/disks/delete",
                    "Microsoft.DevTestLab/schedules/*",
                    "Microsoft.Insights/alertRules/*",
                    "Microsoft.Network/applicationGateways/backendAddressPools/join/action",
                    "Microsoft.Network/loadBalancers/backendAddressPools/join/action",
                    "Microsoft.Network/loadBalancers/inboundNatPools/join/action",
                    "Microsoft.Network/loadBalancers/inboundNatRules/join/action",
                    "Microsoft.Network/loadBalancers/probes/join/action",
                    "Microsoft.Network/loadBalancers/read",
                    "Microsoft.Network/locations/*",
                    "Microsoft.Network/networkInterfaces/*",
                    "Microsoft.Network/networkSecurityGroups/join/action",
                    "Microsoft.Network/networkSecurityGroups/read",
                    "Microsoft.Network/publicIPAddresses/join/action",
                    "Microsoft.Network/publicIPAddresses/read",
                    "Microsoft.Network/virtualNetworks/read",
                    "Microsoft.Network/virtualNetworks/subnets/join/action",
                    "Microsoft.RecoveryServices/locations/*",
                    "Microsoft.RecoveryServices/Vaults/backupFabrics/backupProtectionIntent/write",
                    "Microsoft.RecoveryServices/Vaults/backupFabrics/protectionContainers/protectedItems/*/read",
                    "Microsoft.RecoveryServices/Vaults/backupFabrics/protectionContainers/protectedItems/read",
                    "Microsoft.RecoveryServices/Vaults/backupFabrics/protectionContainers/protectedItems/write",
                    "Microsoft.RecoveryServices/Vaults/backupPolicies/read",
                    "Microsoft.RecoveryServices/Vaults/backupPolicies/write",
                    "Microsoft.RecoveryServices/Vaults/read",
                    "Microsoft.RecoveryServices/Vaults/usages/read",
                    "Microsoft.RecoveryServices/Vaults/write",
                    "Microsoft.ResourceHealth/availabilityStatuses/read",
                    "Microsoft.Resources/deployments/*",
                    "Microsoft.Resources/subscriptions/resourceGroups/read",
                    "Microsoft.SqlVirtualMachine/*",
                    "Microsoft.Storage/storageAccounts/listKeys/action",
                    "Microsoft.Storage/storageAccounts/read",
                    "Microsoft.Support/*" ]
  }

  assignable_scopes = [
    "${data.azurerm_subscription.current.id}",
  ]
}

resource "azurerm_role_assignment" "cac_assignment" {
  name               = "${random_uuid.uuid1.result}"
  scope              = "${data.azurerm_subscription.current.id}"
  role_definition_id = "${azurerm_role_definition.cac_role.id}"
  principal_id       = "${azurerm_policy_assignment.pa_deploy_compute_agents.identity[0].principal_id}"
}

resource "azurerm_role_assignment" "lac_assignment" {
  name               = "${random_uuid.uuid2.result}"
  scope              = "${data.azurerm_subscription.current.id}"
  role_definition_id = "${azurerm_role_definition.lac_role.id}"
  principal_id       = "${azurerm_policy_assignment.pa_deploy_compute_agents.identity[0].principal_id}"
}

resource "azurerm_policy_definition" "deploy_laa_linux" {
  name         = "Deploy Log Analytics Agent for Linux VMs"
  policy_type  = "Custom"
  mode         = "all"
  display_name = "Deploy Log Analytics Agent for Linux VMs"

  metadata = <<METADATA
    {
    "category": "Monitoring"
    }
  METADATA

  policy_rule = <<POLICY_RULE
    {
    "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Compute/virtualMachines"
          },
          {
            "anyOf": [
              {
                "field": "Microsoft.Compute/imageId",
                "in": "[parameters('listOfImageIdToInclude')]"
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "RedHat"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "in": [
                      "RHEL",
                      "RHEL-SAP-HANA"
                    ]
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "6.*"
                      },
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "7*"
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "SUSE"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "in": [
                      "SLES",
                      "SLES-HPC",
                      "SLES-HPC-Priority",
                      "SLES-SAP",
                      "SLES-SAP-BYOS",
                      "SLES-Priority",
                      "SLES-BYOS",
                      "SLES-SAPCAL",
                      "SLES-Standard"
                    ]
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "12*"
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "Canonical"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "UbuntuServer"
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "14.04*LTS"
                      },
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "16.04*LTS"
                      },
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "18.04*LTS"
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "Oracle"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "Oracle-Linux"
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "6.*"
                      },
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "7.*"
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "OpenLogic"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "in": [
                      "CentOS",
                      "Centos-LVM",
                      "CentOS-SRIOV"
                    ]
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "6.*"
                      },
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "7*"
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "cloudera"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "cloudera-centos-os"
                  },
                  {
                    "field": "Microsoft.Compute/imageSKU",
                    "like": "7*"
                  }
                ]
              }
            ]
          }
        ]
      },
      "then": {
        "effect": "deployIfNotExists",
        "details": {
          "type": "Microsoft.Compute/virtualMachines/extensions",
          "roleDefinitionIds": [
            "${azurerm_role_definition.lac_role.id}"
          ],
          "existenceCondition": {
            "allOf": [
              {
                "field": "Microsoft.Compute/virtualMachines/extensions/type",
                "equals": "OmsAgentForLinux"
              },
              {
                "field": "Microsoft.Compute/virtualMachines/extensions/publisher",
                "equals": "Microsoft.EnterpriseCloud.Monitoring"
              },
              {
                "field": "Microsoft.Compute/virtualMachines/extensions/provisioningState",
                "equals": "Succeeded"
              }
            ]
          },
          "deployment": {
            "properties": {
              "mode": "incremental",
              "template": {
                "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                "contentVersion": "1.0.0.0",
                "parameters": {
                  "vmName": {
                    "type": "string"
                  },
                  "location": {
                    "type": "string"
                  },
                  "logAnalytics": {
                    "type": "string"
                  }
                },
                "variables": {
                  "vmExtensionName": "MMAExtension",
                  "vmExtensionPublisher": "Microsoft.EnterpriseCloud.Monitoring",
                  "vmExtensionType": "OmsAgentForLinux",
                  "vmExtensionTypeHandlerVersion": "1.7"
                },
                "resources": [
                  {
                    "name": "[concat(parameters('vmName'), '/', variables('vmExtensionName'))]",
                    "type": "Microsoft.Compute/virtualMachines/extensions",
                    "location": "[parameters('location')]",
                    "apiVersion": "2018-06-01",
                    "properties": {
                      "publisher": "[variables('vmExtensionPublisher')]",
                      "type": "[variables('vmExtensionType')]",
                      "typeHandlerVersion": "[variables('vmExtensionTypeHandlerVersion')]",
                      "autoUpgradeMinorVersion": true,
                      "settings": {
                        "workspaceId": "[reference(parameters('logAnalytics'), '2015-03-20').customerId]",
                        "stopOnMultipleConnections": "true"
                      },
                      "protectedSettings": {
                        "workspaceKey": "[listKeys(parameters('logAnalytics'), '2015-03-20').primarySharedKey]"
                      }
                    }
                  }
                ],
                "outputs": {
                  "policy": {
                    "type": "string",
                    "value": "[concat('Enabled extension for VM', ': ', parameters('vmName'))]"
                  }
                }
              },
              "parameters": {
                "vmName": {
                  "value": "[field('name')]"
                },
                "location": {
                  "value": "[field('location')]"
                },
                "logAnalytics": {
                  "value": "[parameters('logAnalytics')]"
                }
              }
            }
          }
        }
      }
    }
POLICY_RULE

  parameters = <<PARAMETERS
    {
    "logAnalytics": {
        "type": "String",
        "metadata": {
          "displayName": "Log Analytics workspace",
          "description": "Select Log Analytics workspace from dropdown list. If this workspace is outside of the scope of the assignment you must manually grant 'Log Analytics Contributor' permissions (or similar) to the policy assignment's principal ID.",
          "strongType": "omsWorkspace",
          "assignPermissions": true
        }
      },
      "listOfImageIdToInclude": {
        "type": "Array",
        "metadata": {
          "displayName": "Optional: List of VM images that have supported Linux OS to add to scope",
          "description": "Example value: '/subscriptions/<subscriptionId>/resourceGroups/YourResourceGroup/providers/Microsoft.Compute/images/ContosoStdImage'"
        },
        "defaultValue": []
      }
    }
PARAMETERS
}

resource "azurerm_policy_definition" "deploy_laa_windows" {
  name         = "Deploy Log Analytics Agent for Windows VMs"
  policy_type  = "Custom"
  mode         = "all"
  display_name = "Deploy Log Analytics Agent for Windows VMs"

  metadata = <<METADATA
    {
    "category": "Monitoring"
    }
  METADATA

  policy_rule = <<POLICY_RULE
    {
    "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Compute/virtualMachines"
          },
          {
            "anyOf": [
              {
                "field": "Microsoft.Compute/imageId",
                "in": "[parameters('listOfImageIdToInclude')]"
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftWindowsServer"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "WindowsServer"
                  },
                  {
                    "field": "Microsoft.Compute/imageSKU",
                    "in": [
                      "2008-R2-SP1",
                      "2008-R2-SP1-smalldisk",
                      "2012-Datacenter",
                      "2012-Datacenter-smalldisk",
                      "2012-R2-Datacenter",
                      "2012-R2-Datacenter-smalldisk",
                      "2016-Datacenter",
                      "2016-Datacenter-Server-Core",
                      "2016-Datacenter-Server-Core-smalldisk",
                      "2016-Datacenter-smalldisk",
                      "2016-Datacenter-with-Containers",
                      "2016-Datacenter-with-RDSH",
                      "2019-Datacenter",
                      "2019-Datacenter-Core",
                      "2019-Datacenter-Core-smalldisk",
                      "2019-Datacenter-Core-with-Containers",
                      "2019-Datacenter-Core-with-Containers-smalldisk",
                      "2019-Datacenter-smalldisk",
                      "2019-Datacenter-with-Containers",
                      "2019-Datacenter-with-Containers-smalldisk",
                      "2019-Datacenter-zhcn"
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftWindowsServer"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "WindowsServerSemiAnnual"
                  },
                  {
                    "field": "Microsoft.Compute/imageSKU",
                    "in": [
                      "Datacenter-Core-1709-smalldisk",
                      "Datacenter-Core-1709-with-Containers-smalldisk",
                      "Datacenter-Core-1803-with-Containers-smalldisk"
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftWindowsServerHPCPack"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "WindowsServerHPCPack"
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftSQLServer"
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "like": "*-WS2016"
                      },
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "like": "*-WS2016-BYOL"
                      },
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "like": "*-WS2012R2"
                      },
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "like": "*-WS2012R2-BYOL"
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftRServer"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "MLServer-WS2016"
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftVisualStudio"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "in": [
                      "VisualStudio",
                      "Windows"
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftDynamicsAX"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "Dynamics"
                  },
                  {
                    "field": "Microsoft.Compute/imageSKU",
                    "equals": "Pre-Req-AX7-Onebox-U8"
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "microsoft-ads"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "windows-data-science-vm"
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftWindowsDesktop"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "Windows-10"
                  }
                ]
              }
            ]
          }
        ]
      },
      "then": {
        "effect": "deployIfNotExists",
        "details": {
          "type": "Microsoft.Compute/virtualMachines/extensions",
          "roleDefinitionIds": [
            "${azurerm_role_definition.lac_role.id}"
          ],
          "existenceCondition": {
            "allOf": [
              {
                "field": "Microsoft.Compute/virtualMachines/extensions/type",
                "equals": "MicrosoftMonitoringAgent"
              },
              {
                "field": "Microsoft.Compute/virtualMachines/extensions/publisher",
                "equals": "Microsoft.EnterpriseCloud.Monitoring"
              },
              {
                "field": "Microsoft.Compute/virtualMachines/extensions/provisioningState",
                "equals": "Succeeded"
              }
            ]
          },
          "deployment": {
            "properties": {
              "mode": "incremental",
              "template": {
                "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                "contentVersion": "1.0.0.0",
                "parameters": {
                  "vmName": {
                    "type": "string"
                  },
                  "location": {
                    "type": "string"
                  },
                  "logAnalytics": {
                    "type": "string"
                  }
                },
                "variables": {
                  "vmExtensionName": "MMAExtension",
                  "vmExtensionPublisher": "Microsoft.EnterpriseCloud.Monitoring",
                  "vmExtensionType": "MicrosoftMonitoringAgent",
                  "vmExtensionTypeHandlerVersion": "1.0"
                },
                "resources": [
                  {
                    "name": "[concat(parameters('vmName'), '/', variables('vmExtensionName'))]",
                    "type": "Microsoft.Compute/virtualMachines/extensions",
                    "location": "[parameters('location')]",
                    "apiVersion": "2018-06-01",
                    "properties": {
                      "publisher": "[variables('vmExtensionPublisher')]",
                      "type": "[variables('vmExtensionType')]",
                      "typeHandlerVersion": "[variables('vmExtensionTypeHandlerVersion')]",
                      "autoUpgradeMinorVersion": true,
                      "settings": {
                        "workspaceId": "[reference(parameters('logAnalytics'), '2015-03-20').customerId]",
                        "stopOnMultipleConnections": "true"
                      },
                      "protectedSettings": {
                        "workspaceKey": "[listKeys(parameters('logAnalytics'), '2015-03-20').primarySharedKey]"
                      }
                    }
                  }
                ],
                "outputs": {
                  "policy": {
                    "type": "string",
                    "value": "[concat('Enabled extension for VM', ': ', parameters('vmName'))]"
                  }
                }
              },
              "parameters": {
                "vmName": {
                  "value": "[field('name')]"
                },
                "location": {
                  "value": "[field('location')]"
                },
                "logAnalytics": {
                  "value": "[parameters('logAnalytics')]"
                }
              }
            }
          }
        }
      }
    }
POLICY_RULE

  parameters = <<PARAMETERS
    {
    "logAnalytics": {
        "type": "String",
        "metadata": {
          "displayName": "Log Analytics workspace",
          "description": "Select Log Analytics workspace from dropdown list. If this workspace is outside of the scope of the assignment you must manually grant 'Log Analytics Contributor' permissions (or similar) to the policy assignment's principal ID.",
          "strongType": "omsWorkspace",
          "assignPermissions": true
        }
      },
      "listOfImageIdToInclude": {
        "type": "Array",
        "metadata": {
          "displayName": "Optional: List of VM images that have supported Windows OS to add to scope",
          "description": "Example values: '/subscriptions/<subscriptionId>/resourceGroups/YourResourceGroup/providers/Microsoft.Compute/images/ContosoStdImage'"
        },
        "defaultValue": []
      }
    }
PARAMETERS
}

resource "azurerm_policy_definition" "deploy_laa_windows_vmss" {
  name         = "Deploy Log Analytics Agent for Windows VM Scale Sets (VMSS)"
  policy_type  = "Custom"
  mode         = "all"
  display_name = "Deploy Log Analytics Agent for Windows VM Scale Sets (VMSS)"

  metadata = <<METADATA
    {
    "category": "Monitoring"
    }
  METADATA

  policy_rule = <<POLICY_RULE
    {
    "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Compute/virtualMachineScaleSets"
          },
          {
            "anyOf": [
              {
                "field": "Microsoft.Compute/imageId",
                "in": "[parameters('listOfImageIdToInclude')]"
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftWindowsServer"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "WindowsServer"
                  },
                  {
                    "field": "Microsoft.Compute/imageSKU",
                    "in": [
                      "2008-R2-SP1",
                      "2008-R2-SP1-smalldisk",
                      "2012-Datacenter",
                      "2012-Datacenter-smalldisk",
                      "2012-R2-Datacenter",
                      "2012-R2-Datacenter-smalldisk",
                      "2016-Datacenter",
                      "2016-Datacenter-Server-Core",
                      "2016-Datacenter-Server-Core-smalldisk",
                      "2016-Datacenter-smalldisk",
                      "2016-Datacenter-with-Containers",
                      "2016-Datacenter-with-RDSH",
                      "2019-Datacenter",
                      "2019-Datacenter-Core",
                      "2019-Datacenter-Core-smalldisk",
                      "2019-Datacenter-Core-with-Containers",
                      "2019-Datacenter-Core-with-Containers-smalldisk",
                      "2019-Datacenter-smalldisk",
                      "2019-Datacenter-with-Containers",
                      "2019-Datacenter-with-Containers-smalldisk",
                      "2019-Datacenter-zhcn"
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftWindowsServer"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "WindowsServerSemiAnnual"
                  },
                  {
                    "field": "Microsoft.Compute/imageSKU",
                    "in": [
                      "Datacenter-Core-1709-smalldisk",
                      "Datacenter-Core-1709-with-Containers-smalldisk",
                      "Datacenter-Core-1803-with-Containers-smalldisk"
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftWindowsServerHPCPack"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "WindowsServerHPCPack"
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftSQLServer"
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "like": "*-WS2016"
                      },
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "like": "*-WS2016-BYOL"
                      },
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "like": "*-WS2012R2"
                      },
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "like": "*-WS2012R2-BYOL"
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftRServer"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "MLServer-WS2016"
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftVisualStudio"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "in": [
                      "VisualStudio",
                      "Windows"
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftDynamicsAX"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "Dynamics"
                  },
                  {
                    "field": "Microsoft.Compute/imageSKU",
                    "equals": "Pre-Req-AX7-Onebox-U8"
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "microsoft-ads"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "windows-data-science-vm"
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftWindowsDesktop"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "Windows-10"
                  }
                ]
              }
            ]
          }
        ]
      },
      "then": {
        "effect": "deployIfNotExists",
        "details": {
          "type": "Microsoft.Compute/virtualMachineScaleSets/extensions",
          "roleDefinitionIds": [
            "${azurerm_role_definition.lac_role.id}",
            "${azurerm_role_definition.cac_role.id}"
          ],
          "existenceCondition": {
            "allOf": [
              {
                "field": "Microsoft.Compute/virtualMachineScaleSets/extensions/type",
                "equals": "MicrosoftMonitoringAgent"
              },
              {
                "field": "Microsoft.Compute/virtualMachineScaleSets/extensions/publisher",
                "equals": "Microsoft.EnterpriseCloud.Monitoring"
              }
            ]
          },
          "deployment": {
            "properties": {
              "mode": "incremental",
              "template": {
                "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                "contentVersion": "1.0.0.0",
                "parameters": {
                  "vmName": {
                    "type": "string"
                  },
                  "location": {
                    "type": "string"
                  },
                  "logAnalytics": {
                    "type": "string"
                  }
                },
                "variables": {
                  "vmExtensionName": "MMAExtension",
                  "vmExtensionPublisher": "Microsoft.EnterpriseCloud.Monitoring",
                  "vmExtensionType": "MicrosoftMonitoringAgent",
                  "vmExtensionTypeHandlerVersion": "1.0"
                },
                "resources": [
                  {
                    "name": "[concat(parameters('vmName'), '/', variables('vmExtensionName'))]",
                    "type": "Microsoft.Compute/virtualMachineScaleSets/extensions",
                    "location": "[parameters('location')]",
                    "apiVersion": "2018-06-01",
                    "properties": {
                      "publisher": "[variables('vmExtensionPublisher')]",
                      "type": "[variables('vmExtensionType')]",
                      "typeHandlerVersion": "[variables('vmExtensionTypeHandlerVersion')]",
                      "autoUpgradeMinorVersion": true,
                      "settings": {
                        "workspaceId": "[reference(parameters('logAnalytics'), '2015-03-20').customerId]",
                        "stopOnMultipleConnections": "true"
                      },
                      "protectedSettings": {
                        "workspaceKey": "[listKeys(parameters('logAnalytics'), '2015-03-20').primarySharedKey]"
                      }
                    }
                  }
                ],
                "outputs": {
                  "policy": {
                    "type": "string",
                    "value": "[concat('Enabled extension for: ', parameters('vmName'))]"
                  }
                }
              },
              "parameters": {
                "vmName": {
                  "value": "[field('name')]"
                },
                "location": {
                  "value": "[field('location')]"
                },
                "logAnalytics": {
                  "value": "[parameters('logAnalytics')]"
                }
              }
            }
          }
        }
      }
    }
POLICY_RULE

  parameters = <<PARAMETERS
    {
    "logAnalytics": {
        "type": "String",
        "metadata": {
          "displayName": "Log Analytics workspace",
          "description": "Select Log Analytics workspace from dropdown list. If this workspace is outside of the scope of the assignment you must manually grant 'Log Analytics Contributor' permissions (or similar) to the policy assignment's principal ID.",
          "strongType": "omsWorkspace",
          "assignPermissions": true
        }
      },
      "listOfImageIdToInclude": {
        "type": "Array",
        "metadata": {
          "displayName": "Optional: List of VM images that have supported Windows OS to add to scope",
          "description": "Example value: '/subscriptions/<subscriptionId>/resourceGroups/YourResourceGroup/providers/Microsoft.Compute/images/ContosoStdImage'"
        },
        "defaultValue": []
      }
    }
PARAMETERS
}

resource "azurerm_policy_definition" "deploy_laa_linux_vmss" {
  name         = "Deploy Log Analytics Agent for Linux VM Scale Sets (VMSS)"
  policy_type  = "Custom"
  mode         = "all"
  display_name = "Deploy Log Analytics Agent for Linux VM Scale Sets (VMSS)"

  metadata = <<METADATA
    {
    "category": "Monitoring"
    }
  METADATA

  policy_rule = <<POLICY_RULE
    {
    "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Compute/virtualMachineScaleSets"
          },
          {
            "anyOf": [
              {
                "field": "Microsoft.Compute/imageId",
                "in": "[parameters('listOfImageIdToInclude')]"
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "RedHat"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "in": [
                      "RHEL",
                      "RHEL-SAP-HANA"
                    ]
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "6.*"
                      },
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "7*"
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "SUSE"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "in": [
                      "SLES",
                      "SLES-HPC",
                      "SLES-HPC-Priority",
                      "SLES-SAP",
                      "SLES-SAP-BYOS",
                      "SLES-Priority",
                      "SLES-BYOS",
                      "SLES-SAPCAL",
                      "SLES-Standard"
                    ]
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "12*"
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "Canonical"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "UbuntuServer"
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "14.04*LTS"
                      },
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "16.04*LTS"
                      },
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "18.04*LTS"
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "Oracle"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "Oracle-Linux"
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "6.*"
                      },
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "7.*"
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "OpenLogic"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "in": [
                      "CentOS",
                      "Centos-LVM",
                      "CentOS-SRIOV"
                    ]
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "6.*"
                      },
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "7*"
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "cloudera"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "cloudera-centos-os"
                  },
                  {
                    "field": "Microsoft.Compute/imageSKU",
                    "like": "7*"
                  }
                ]
              }
            ]
          }
        ]
      },
      "then": {
        "effect": "deployIfNotExists",
        "details": {
          "type": "Microsoft.Compute/virtualMachineScaleSets/extensions",
          "roleDefinitionIds": [
            "${azurerm_role_definition.lac_role.id}",
            "${azurerm_role_definition.cac_role.id}"
          ],
          "existenceCondition": {
            "allOf": [
              {
                "field": "Microsoft.Compute/virtualMachineScaleSets/extensions/type",
                "equals": "OmsAgentForLinux"
              },
              {
                "field": "Microsoft.Compute/virtualMachineScaleSets/extensions/publisher",
                "equals": "Microsoft.EnterpriseCloud.Monitoring"
              }
            ]
          },
          "deployment": {
            "properties": {
              "mode": "incremental",
              "template": {
                "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                "contentVersion": "1.0.0.0",
                "parameters": {
                  "vmName": {
                    "type": "string"
                  },
                  "location": {
                    "type": "string"
                  },
                  "logAnalytics": {
                    "type": "string"
                  }
                },
                "variables": {
                  "vmExtensionName": "MMAExtension",
                  "vmExtensionPublisher": "Microsoft.EnterpriseCloud.Monitoring",
                  "vmExtensionType": "OmsAgentForLinux",
                  "vmExtensionTypeHandlerVersion": "1.7"
                },
                "resources": [
                  {
                    "name": "[concat(parameters('vmName'), '/', variables('vmExtensionName'))]",
                    "type": "Microsoft.Compute/virtualMachineScaleSets/extensions",
                    "location": "[parameters('location')]",
                    "apiVersion": "2018-06-01",
                    "properties": {
                      "publisher": "[variables('vmExtensionPublisher')]",
                      "type": "[variables('vmExtensionType')]",
                      "typeHandlerVersion": "[variables('vmExtensionTypeHandlerVersion')]",
                      "autoUpgradeMinorVersion": true,
                      "settings": {
                        "workspaceId": "[reference(parameters('logAnalytics'), '2015-03-20').customerId]",
                        "stopOnMultipleConnections": "true"
                      },
                      "protectedSettings": {
                        "workspaceKey": "[listKeys(parameters('logAnalytics'), '2015-03-20').primarySharedKey]"
                      }
                    }
                  }
                ],
                "outputs": {
                  "policy": {
                    "type": "string",
                    "value": "[concat('Enabled extension for: ', parameters('vmName'))]"
                  }
                }
              },
              "parameters": {
                "vmName": {
                  "value": "[field('name')]"
                },
                "location": {
                  "value": "[field('location')]"
                },
                "logAnalytics": {
                  "value": "[parameters('logAnalytics')]"
                }
              }
            }
          }
        }
      }
    }
POLICY_RULE

  parameters = <<PARAMETERS
    {
    "logAnalytics": {
        "type": "String",
        "metadata": {
          "displayName": "Log Analytics workspace",
          "description": "Select Log Analytics workspace from dropdown list. If this workspace is outside of the scope of the assignment you must manually grant 'Log Analytics Contributor' permissions (or similar) to the policy assignment's principal ID.",
          "strongType": "omsWorkspace",
          "assignPermissions": true
        }
      },
      "listOfImageIdToInclude": {
        "type": "Array",
        "metadata": {
          "displayName": "Optional: List of VM images that have supported Linux OS to add to scope",
          "description": "Example value: '/subscriptions/<subscriptionId>/resourceGroups/YourResourceGroup/providers/Microsoft.Compute/images/ContosoStdImage'"
        },
        "defaultValue": []
      }
    }
PARAMETERS
}

resource "azurerm_policy_definition" "deploy_da_windows" {
  name         = "Deploy Dependency Agent for Windows VMs"
  policy_type  = "Custom"
  mode         = "all"
  display_name = "Deploy Dependency Agent for Windows VMs"

  metadata = <<METADATA
    {
    "category": "Monitoring"
    }
  METADATA

  policy_rule = <<POLICY_RULE
    {
    "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Compute/virtualMachines"
          },
          {
            "anyOf": [
              {
                "field": "Microsoft.Compute/imageId",
                "in": "[parameters('listOfImageIdToInclude')]"
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftWindowsServer"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "WindowsServer"
                  },
                  {
                    "field": "Microsoft.Compute/imageSKU",
                    "in": [
                      "2008-R2-SP1",
                      "2008-R2-SP1-smalldisk",
                      "2012-Datacenter",
                      "2012-Datacenter-smalldisk",
                      "2012-R2-Datacenter",
                      "2012-R2-Datacenter-smalldisk",
                      "2016-Datacenter",
                      "2016-Datacenter-Server-Core",
                      "2016-Datacenter-Server-Core-smalldisk",
                      "2016-Datacenter-smalldisk",
                      "2016-Datacenter-with-Containers",
                      "2016-Datacenter-with-RDSH",
                      "2019-Datacenter",
                      "2019-Datacenter-Core",
                      "2019-Datacenter-Core-smalldisk",
                      "2019-Datacenter-Core-with-Containers",
                      "2019-Datacenter-Core-with-Containers-smalldisk",
                      "2019-Datacenter-smalldisk",
                      "2019-Datacenter-with-Containers",
                      "2019-Datacenter-with-Containers-smalldisk",
                      "2019-Datacenter-zhcn"
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftWindowsServer"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "WindowsServerSemiAnnual"
                  },
                  {
                    "field": "Microsoft.Compute/imageSKU",
                    "in": [
                      "Datacenter-Core-1709-smalldisk",
                      "Datacenter-Core-1709-with-Containers-smalldisk",
                      "Datacenter-Core-1803-with-Containers-smalldisk"
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftWindowsServerHPCPack"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "WindowsServerHPCPack"
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftSQLServer"
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "like": "*-WS2016"
                      },
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "like": "*-WS2016-BYOL"
                      },
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "like": "*-WS2012R2"
                      },
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "like": "*-WS2012R2-BYOL"
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftRServer"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "MLServer-WS2016"
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftVisualStudio"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "in": [
                      "VisualStudio",
                      "Windows"
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftDynamicsAX"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "Dynamics"
                  },
                  {
                    "field": "Microsoft.Compute/imageSKU",
                    "equals": "Pre-Req-AX7-Onebox-U8"
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "microsoft-ads"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "windows-data-science-vm"
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftWindowsDesktop"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "Windows-10"
                  }
                ]
              }
            ]
          }
        ]
      },
      "then": {
        "effect": "deployIfNotExists",
        "details": {
          "type": "Microsoft.Compute/virtualMachines/extensions",
          "roleDefinitionIds": [
            "${azurerm_role_definition.lac_role.id}"
          ],
          "existenceCondition": {
            "allOf": [
              {
                "field": "Microsoft.Compute/virtualMachines/extensions/type",
                "equals": "DependencyAgentWindows"
              },
              {
                "field": "Microsoft.Compute/virtualMachines/extensions/publisher",
                "equals": "Microsoft.Azure.Monitoring.DependencyAgent"
              },
              {
                "field": "Microsoft.Compute/virtualMachines/extensions/provisioningState",
                "equals": "Succeeded"
              }
            ]
          },
          "deployment": {
            "properties": {
              "mode": "incremental",
              "template": {
                "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                "contentVersion": "1.0.0.0",
                "parameters": {
                  "vmName": {
                    "type": "string"
                  },
                  "location": {
                    "type": "string"
                  }
                },
                "variables": {
                  "vmExtensionName": "DependencyAgent",
                  "vmExtensionPublisher": "Microsoft.Azure.Monitoring.DependencyAgent",
                  "vmExtensionType": "DependencyAgentWindows",
                  "vmExtensionTypeHandlerVersion": "9.6"
                },
                "resources": [
                  {
                    "type": "Microsoft.Compute/virtualMachines/extensions",
                    "name": "[concat(parameters('vmName'), '/', variables('vmExtensionName'))]",
                    "apiVersion": "2018-06-01",
                    "location": "[parameters('location')]",
                    "properties": {
                      "publisher": "[variables('vmExtensionPublisher')]",
                      "type": "[variables('vmExtensionType')]",
                      "typeHandlerVersion": "[variables('vmExtensionTypeHandlerVersion')]",
                      "autoUpgradeMinorVersion": true
                    }
                  }
                ],
                "outputs": {
                  "policy": {
                    "type": "string",
                    "value": "[concat('Enabled extension for VM', ': ', parameters('vmName'))]"
                  }
                }
              },
              "parameters": {
                "vmName": {
                  "value": "[field('name')]"
                },
                "location": {
                  "value": "[field('location')]"
                }
              }
            }
          }
        }
      }
    }
POLICY_RULE

  parameters = <<PARAMETERS
    {
    "listOfImageIdToInclude": {
        "type": "Array",
        "metadata": {
          "displayName": "Optional: List of VM images that have supported Windows OS to add to scope",
          "description": "Example value: '/subscriptions/<subscriptionId>/resourceGroups/YourResourceGroup/providers/Microsoft.Compute/images/ContosoStdImage'"
        },
        "defaultValue": []
      }
    }
PARAMETERS
}

resource "azurerm_policy_definition" "deploy_da_linux" {
  name         = "Deploy Dependency Agent for Linux VMs"
  policy_type  = "Custom"
  mode         = "all"
  display_name = "Deploy Dependency Agent for Linux VMs"

  metadata = <<METADATA
    {
    "category": "Monitoring"
    }
  METADATA

  policy_rule = <<POLICY_RULE
    {
    "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Compute/virtualMachines"
          },
          {
            "anyOf": [
              {
                "field": "Microsoft.Compute/imageId",
                "in": "[parameters('listOfImageIdToInclude')]"
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "Canonical"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "UbuntuServer"
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "in": [
                          "14.04.0-LTS",
                          "14.04.1-LTS",
                          "14.04.5-LTS"
                        ]
                      },
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "in": [
                          "16.04-LTS",
                          "16.04.0-LTS"
                        ]
                      },
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "in": [
                          "18.04-LTS"
                        ]
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "RedHat"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "in": [
                      "RHEL",
                      "RHEL-SAP-HANA"
                    ]
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "6.*"
                      },
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "7*"
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "SUSE"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "in": [
                      "SLES",
                      "SLES-HPC",
                      "SLES-HPC-Priority",
                      "SLES-SAP",
                      "SLES-SAP-BYOS",
                      "SLES-Priority",
                      "SLES-BYOS",
                      "SLES-SAPCAL",
                      "SLES-Standard"
                    ]
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "in": [
                          "12-SP2",
                          "12-SP3",
                          "12-SP4"
                        ]
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "OpenLogic"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "in": [
                      "CentOS",
                      "Centos-LVM",
                      "CentOS-SRIOV"
                    ]
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "6.*"
                      },
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "7*"
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "cloudera"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "cloudera-centos-os"
                  },
                  {
                    "field": "Microsoft.Compute/imageSKU",
                    "like": "7*"
                  }
                ]
              }
            ]
          }
        ]
      },
      "then": {
        "effect": "deployIfNotExists",
        "details": {
          "type": "Microsoft.Compute/virtualMachines/extensions",
          "roleDefinitionIds": [
            "${azurerm_role_definition.lac_role.id}"
          ],
          "existenceCondition": {
            "allOf": [
              {
                "field": "Microsoft.Compute/virtualMachines/extensions/type",
                "equals": "DependencyAgentLinux"
              },
              {
                "field": "Microsoft.Compute/virtualMachines/extensions/publisher",
                "equals": "Microsoft.Azure.Monitoring.DependencyAgent"
              },
              {
                "field": "Microsoft.Compute/virtualMachines/extensions/provisioningState",
                "equals": "Succeeded"
              }
            ]
          },
          "deployment": {
            "properties": {
              "mode": "incremental",
              "template": {
                "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                "contentVersion": "1.0.0.0",
                "parameters": {
                  "vmName": {
                    "type": "string"
                  },
                  "location": {
                    "type": "string"
                  }
                },
                "variables": {
                  "vmExtensionName": "DependencyAgent",
                  "vmExtensionPublisher": "Microsoft.Azure.Monitoring.DependencyAgent",
                  "vmExtensionType": "DependencyAgentLinux",
                  "vmExtensionTypeHandlerVersion": "9.6"
                },
                "resources": [
                  {
                    "type": "Microsoft.Compute/virtualMachines/extensions",
                    "name": "[concat(parameters('vmName'), '/', variables('vmExtensionName'))]",
                    "apiVersion": "2018-06-01",
                    "location": "[parameters('location')]",
                    "properties": {
                      "publisher": "[variables('vmExtensionPublisher')]",
                      "type": "[variables('vmExtensionType')]",
                      "typeHandlerVersion": "[variables('vmExtensionTypeHandlerVersion')]",
                      "autoUpgradeMinorVersion": true
                    }
                  }
                ],
                "outputs": {
                  "policy": {
                    "type": "string",
                    "value": "[concat('Enabled extension for VM', ': ', parameters('vmName'))]"
                  }
                }
              },
              "parameters": {
                "vmName": {
                  "value": "[field('name')]"
                },
                "location": {
                  "value": "[field('location')]"
                }
              }
            }
          }
        }
      }
    }
POLICY_RULE

  parameters = <<PARAMETERS
    {
    "listOfImageIdToInclude": {
        "type": "Array",
        "metadata": {
          "displayName": "Optional: List of VM images that have supported Linux OS to add to scope",
          "description": "Example value: '/subscriptions/<subscriptionId>/resourceGroups/YourResourceGroup/providers/Microsoft.Compute/images/ContosoStdImage'"
        },
        "defaultValue": []
      }
    }
PARAMETERS
}

resource "azurerm_policy_definition" "deploy_da_windows_vmss" {
  name         = "Deploy Dependency Agent for Windows VM Scale Sets (VMSS)"
  policy_type  = "Custom"
  mode         = "all"
  display_name = "Deploy Dependency Agent for Windows VM Scale Sets (VMSS)"

  metadata = <<METADATA
    {
    "category": "Monitoring"
    }
  METADATA

  policy_rule = <<POLICY_RULE
    {
    "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Compute/virtualMachineScaleSets"
          },
          {
            "anyOf": [
              {
                "field": "Microsoft.Compute/imageId",
                "in": "[parameters('listOfImageIdToInclude')]"
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftWindowsServer"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "WindowsServer"
                  },
                  {
                    "field": "Microsoft.Compute/imageSKU",
                    "in": [
                      "2008-R2-SP1",
                      "2008-R2-SP1-smalldisk",
                      "2012-Datacenter",
                      "2012-Datacenter-smalldisk",
                      "2012-R2-Datacenter",
                      "2012-R2-Datacenter-smalldisk",
                      "2016-Datacenter",
                      "2016-Datacenter-Server-Core",
                      "2016-Datacenter-Server-Core-smalldisk",
                      "2016-Datacenter-smalldisk",
                      "2016-Datacenter-with-Containers",
                      "2016-Datacenter-with-RDSH",
                      "2019-Datacenter",
                      "2019-Datacenter-Core",
                      "2019-Datacenter-Core-smalldisk",
                      "2019-Datacenter-Core-with-Containers",
                      "2019-Datacenter-Core-with-Containers-smalldisk",
                      "2019-Datacenter-smalldisk",
                      "2019-Datacenter-with-Containers",
                      "2019-Datacenter-with-Containers-smalldisk",
                      "2019-Datacenter-zhcn"
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftWindowsServer"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "WindowsServerSemiAnnual"
                  },
                  {
                    "field": "Microsoft.Compute/imageSKU",
                    "in": [
                      "Datacenter-Core-1709-smalldisk",
                      "Datacenter-Core-1709-with-Containers-smalldisk",
                      "Datacenter-Core-1803-with-Containers-smalldisk"
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftWindowsServerHPCPack"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "WindowsServerHPCPack"
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftSQLServer"
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "like": "*-WS2016"
                      },
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "like": "*-WS2016-BYOL"
                      },
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "like": "*-WS2012R2"
                      },
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "like": "*-WS2012R2-BYOL"
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftRServer"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "MLServer-WS2016"
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftVisualStudio"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "in": [
                      "VisualStudio",
                      "Windows"
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftDynamicsAX"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "Dynamics"
                  },
                  {
                    "field": "Microsoft.Compute/imageSKU",
                    "equals": "Pre-Req-AX7-Onebox-U8"
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "microsoft-ads"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "windows-data-science-vm"
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "MicrosoftWindowsDesktop"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "Windows-10"
                  }
                ]
              }
            ]
          }
        ]
      },
      "then": {
        "effect": "deployIfNotExists",
        "details": {
          "type": "Microsoft.Compute/virtualMachineScaleSets/extensions",
          "roleDefinitionIds": [
            "${azurerm_role_definition.cac_role.id}"
          ],
          "existenceCondition": {
            "allOf": [
              {
                "field": "Microsoft.Compute/virtualMachineScaleSets/extensions/type",
                "equals": "DependencyAgentWindows"
              },
              {
                "field": "Microsoft.Compute/virtualMachineScaleSets/extensions/publisher",
                "equals": "Microsoft.Azure.Monitoring.DependencyAgent"
              }
            ]
          },
          "deployment": {
            "properties": {
              "mode": "incremental",
              "template": {
                "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                "contentVersion": "1.0.0.0",
                "parameters": {
                  "vmName": {
                    "type": "string"
                  },
                  "location": {
                    "type": "string"
                  }
                },
                "variables": {
                  "vmExtensionName": "DependencyAgent",
                  "vmExtensionPublisher": "Microsoft.Azure.Monitoring.DependencyAgent",
                  "vmExtensionType": "DependencyAgentWindows",
                  "vmExtensionTypeHandlerVersion": "9.7"
                },
                "resources": [
                  {
                    "type": "Microsoft.Compute/virtualMachineScaleSets/extensions",
                    "name": "[concat(parameters('vmName'), '/', variables('vmExtensionName'))]",
                    "apiVersion": "2018-06-01",
                    "location": "[parameters('location')]",
                    "properties": {
                      "publisher": "[variables('vmExtensionPublisher')]",
                      "type": "[variables('vmExtensionType')]",
                      "typeHandlerVersion": "[variables('vmExtensionTypeHandlerVersion')]",
                      "autoUpgradeMinorVersion": true
                    }
                  }
                ],
                "outputs": {
                  "policy": {
                    "type": "string",
                    "value": "[concat('Enabled extension for: ', parameters('vmName'))]"
                  }
                }
              },
              "parameters": {
                "vmName": {
                  "value": "[field('name')]"
                },
                "location": {
                  "value": "[field('location')]"
                }
              }
            }
          }
        }
      }
    }
POLICY_RULE

  parameters = <<PARAMETERS
    {
    "listOfImageIdToInclude": {
        "type": "Array",
        "metadata": {
          "displayName": "Optional: List of VM images that have supported Windows OS to add to scope",
          "description": "Example value: '/subscriptions/<subscriptionId>/resourceGroups/YourResourceGroup/providers/Microsoft.Compute/images/ContosoStdImage'"
        },
        "defaultValue": []
      }
    }
PARAMETERS
}

resource "azurerm_policy_definition" "deploy_da_linux_vmss" {
  name         = "Deploy Dependency Agent for Linux VM Scale Sets (VMSS)"
  policy_type  = "Custom"
  mode         = "all"
  display_name = "Deploy Dependency Agent for Linux VM Scale Sets (VMSS)"

  metadata = <<METADATA
    {
    "category": "Monitoring"
    }
  METADATA

  policy_rule = <<POLICY_RULE
    {
    "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Compute/virtualMachineScaleSets"
          },
          {
            "anyOf": [
              {
                "field": "Microsoft.Compute/imageId",
                "in": "[parameters('listOfImageIdToInclude')]"
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "Canonical"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "UbuntuServer"
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "in": [
                          "14.04.0-LTS",
                          "14.04.1-LTS",
                          "14.04.5-LTS"
                        ]
                      },
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "in": [
                          "16.04-LTS",
                          "16.04.0-LTS"
                        ]
                      },
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "in": [
                          "18.04-LTS"
                        ]
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "RedHat"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "in": [
                      "RHEL",
                      "RHEL-SAP-HANA"
                    ]
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "6.*"
                      },
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "7*"
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "SUSE"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "in": [
                      "SLES",
                      "SLES-HPC",
                      "SLES-HPC-Priority",
                      "SLES-SAP",
                      "SLES-SAP-BYOS",
                      "SLES-Priority",
                      "SLES-BYOS",
                      "SLES-SAPCAL",
                      "SLES-Standard"
                    ]
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "in": [
                          "12-SP2",
                          "12-SP3",
                          "12-SP4"
                        ]
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "OpenLogic"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "in": [
                      "CentOS",
                      "Centos-LVM",
                      "CentOS-SRIOV"
                    ]
                  },
                  {
                    "anyOf": [
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "6.*"
                      },
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "like": "7*"
                      }
                    ]
                  }
                ]
              },
              {
                "allOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "equals": "cloudera"
                  },
                  {
                    "field": "Microsoft.Compute/imageOffer",
                    "equals": "cloudera-centos-os"
                  },
                  {
                    "field": "Microsoft.Compute/imageSKU",
                    "like": "7*"
                  }
                ]
              }
            ]
          }
        ]
      },
      "then": {
        "effect": "deployIfNotExists",
        "details": {
          "type": "Microsoft.Compute/virtualMachineScaleSets/extensions",
          "roleDefinitionIds": [
            "${azurerm_role_definition.cac_role.id}"
          ],
          "existenceCondition": {
            "allOf": [
              {
                "field": "Microsoft.Compute/virtualMachineScaleSets/extensions/type",
                "equals": "DependencyAgentLinux"
              },
              {
                "field": "Microsoft.Compute/virtualMachineScaleSets/extensions/publisher",
                "equals": "Microsoft.Azure.Monitoring.DependencyAgent"
              }
            ]
          },
          "deployment": {
            "properties": {
              "mode": "incremental",
              "template": {
                "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                "contentVersion": "1.0.0.0",
                "parameters": {
                  "vmName": {
                    "type": "string"
                  },
                  "location": {
                    "type": "string"
                  }
                },
                "variables": {
                  "vmExtensionName": "DependencyAgent",
                  "vmExtensionPublisher": "Microsoft.Azure.Monitoring.DependencyAgent",
                  "vmExtensionType": "DependencyAgentLinux",
                  "vmExtensionTypeHandlerVersion": "9.7"
                },
                "resources": [
                  {
                    "type": "Microsoft.Compute/virtualMachineScaleSets/extensions",
                    "name": "[concat(parameters('vmName'), '/', variables('vmExtensionName'))]",
                    "apiVersion": "2018-06-01",
                    "location": "[parameters('location')]",
                    "properties": {
                      "publisher": "[variables('vmExtensionPublisher')]",
                      "type": "[variables('vmExtensionType')]",
                      "typeHandlerVersion": "[variables('vmExtensionTypeHandlerVersion')]",
                      "autoUpgradeMinorVersion": true
                    }
                  }
                ],
                "outputs": {
                  "policy": {
                    "type": "string",
                    "value": "[concat('Enabled extension for: ', parameters('vmName'))]"
                  }
                }
              },
              "parameters": {
                "vmName": {
                  "value": "[field('name')]"
                },
                "location": {
                  "value": "[field('location')]"
                }
              }
            }
          }
        }
      }
    }
POLICY_RULE

  parameters = <<PARAMETERS
    {
    "listOfImageIdToInclude": {
        "type": "Array",
        "metadata": {
          "displayName": "Optional: List of VM images that have supported Linux OS to add to scope",
          "description": "Example value: '/subscriptions/<subscriptionId>/resourceGroups/YourResourceGroup/providers/Microsoft.Compute/images/ContosoStdImage'"
        },
        "defaultValue": []
      }
    }
PARAMETERS
}

resource "azurerm_policy_set_definition" "deploy_compute_agents" {
  name         = "Deploy Compute Monitoring Agents"
  policy_type  = "Custom"
  display_name = "Deploy Compute Monitoring Agents"
  depends_on = [azurerm_policy_definition.deploy_da_linux,
                azurerm_policy_definition.deploy_da_linux_vmss,
                azurerm_policy_definition.deploy_da_windows,
                azurerm_policy_definition.deploy_da_windows_vmss,
                azurerm_policy_definition.deploy_laa_linux,
                azurerm_policy_definition.deploy_laa_linux_vmss,
                azurerm_policy_definition.deploy_laa_windows,
                azurerm_policy_definition.deploy_laa_windows_vmss]

  metadata = <<METADATA
    {
    "category": "Monitoring"
    }
METADATA

  parameters = <<PARAMETERS
    {
        "logAnalytics": {
            "type": "String",
            "metadata": {
                "description": "Log Analytics Workspace used for log centralization",
                "displayName": "Log Analytics Workspace",
                "strongType": "omsWorkspace"
            }
        }
    }
PARAMETERS

  policy_definitions = <<POLICY_DEFINITIONS
    [
        {
            "parameters": {
                "logAnalytics": {
                    "value": "[parameters('logAnalytics')]"
                }
            },
            "policyDefinitionId": "${azurerm_policy_definition.deploy_laa_linux_vmss.id}"
        },
        {
            "parameters": {
                "logAnalytics": {
                    "value": "[parameters('logAnalytics')]"
                }
            },
            "policyDefinitionId": "${azurerm_policy_definition.deploy_laa_windows_vmss.id}"
        },
        {
            "parameters": {
                "logAnalytics": {
                    "value": "[parameters('logAnalytics')]"
                }
            },
            "policyDefinitionId": "${azurerm_policy_definition.deploy_laa_linux.id}"
        },
        {
            "parameters": {
                "logAnalytics": {
                    "value": "[parameters('logAnalytics')]"
                }
            },
            "policyDefinitionId": "${azurerm_policy_definition.deploy_laa_windows.id}"
        },
        {
            "policyDefinitionId": "${azurerm_policy_definition.deploy_da_windows.id}"
        },
        {
            "policyDefinitionId": "${azurerm_policy_definition.deploy_da_windows_vmss.id}"
        },
        {
            "policyDefinitionId": "${azurerm_policy_definition.deploy_da_linux.id}"
        },
        {
            "policyDefinitionId": "${azurerm_policy_definition.deploy_da_linux_vmss.id}"
        }
    ]
POLICY_DEFINITIONS
}

resource "azurerm_policy_assignment" "pa_deploy_compute_agents" {
  name                 = "PA: Deploy Compute Monitoring Agents"
  scope                = "${data.azurerm_subscription.current.id}"
  policy_definition_id = "${azurerm_policy_set_definition.deploy_compute_agents.id}"
  description          = "Policy assignment created via Terraform to deploy compute monitoring agents"
  display_name         = "PA: Deploy Compute Monitoring Agents"
  location             = "${var.msiLocation}"
  identity {
    type = "SystemAssigned"
  }

  parameters = <<PARAMETERS
{
  "logAnalytics": {
    "value": "/subscriptions/${var.subscriptionId}/resourcegroups/${var.resourceGroup}/providers/microsoft.operationalinsights/workspaces/${var.logAnalyticsWorkspace}"
  }
}
PARAMETERS
}

