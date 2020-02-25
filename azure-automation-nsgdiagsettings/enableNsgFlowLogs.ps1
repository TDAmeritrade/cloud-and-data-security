$connection = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzAccount -ServicePrincipal -Tenant $connection.TenantID -ApplicationID $connection.ApplicationID -CertificateThumbprint $connection.CertificateThumbprint  

$logAnalyticsWorkspaceName = ""
$logAnalyticsResourceGroupName = ""
$logAnalyticsSubscriptionId = ""

$storageAccountRegions = @{ "eastus2" = "";
                            "northcentralus" = "";
                            "eastus" = ""; }
$storageAccountResourceGroupName = ""
$storageAccountSubscriptionId = ""

Select-AzSubscription -Subscription $logAnalyticsSubscriptionId

try {
  $logAnalytics = Get-AzOperationalInsightsWorkspace -ResourceGroupName $logAnalyticsResourceGroupName -Name $logAnalyticsWorkspaceName 
  $workspaceId = $logAnalytics.ResourceId
  Write-Host "$workspaceId"
}
catch {
  Write-Host "Error: $_"
}

Select-AzSubscription -Subscription $storageAccountSubscriptionId

try {
  $storageObj = @()
  foreach ($key in $storageAccountRegions.keys) {
    try {
      $obj = New-Object -TypeName psobject 
      $obj | Add-Member -MemberType NoteProperty -Name Reg -Value $key
      $obj | Add-Member -MemberType NoteProperty -Name obj -Value $(Get-AzStorageAccount -ResourceGroupName $storageAccountResourceGroupName -Name $storageAccountRegions[$key]).id
      $storageObj += $obj
    }
    catch {
      "Error: $_"

    }
  }
}
catch {
  "Error: $_"
}

$subscriptions = Get-AzSubscription

try {  
  foreach ($subscription in $subscriptions) {
             
    try {
      $networkWatcher = Get-AzNetworkWatcher
    }
    catch {
      "Error: $_"
    }

    Select-AzSubscription -Subscription $subscription | Out-Null
    $resourceGroups = Get-AzResourceGroup
    foreach ($resourceGroup in $resourceGroups) {
      $resources = Get-AzResource -ResourceGroupName $resourceGroup.ResourceGroupName -ResourceType "Microsoft.Network/networkSecurityGroups"
      foreach ($resource in $resources) {                              
        $logstatus = Get-AzNetworkWatcherFlowLogStatus -TargetResourceId $resource.id -Location $resource.Location -ErrorAction SilentlyContinue
        if (!$logstatus) {
          New-AzNetworkWatcher -Name $("NetworkWatcher_$($resource.Location)") -ResourceGroupName NetworkWatcherRG -Location $resource.Location                                   
        }
        $logstatus = Get-AzNetworkWatcherFlowLogStatus -TargetResourceId $resource.id -Location $resource.Location -ErrorAction SilentlyContinue
        if ($obj = $storageObj | ? { $_.Reg -eq $($resource.Location) }) {
          $storageAccountobjid = $obj.obj
        }
        if (!$logstatus.Enabled) {   
          $networkWatcher = Get-AzNetworkWatcher -ResourceGroupName NetworkWatcherRG -Name $("NetworkWatcher_$($resource.Location)")  
          try {     
            Set-AzNetworkWatcherConfigFlowLog -NetworkWatcher $networkWatcher -TargetResourceId $resource.Id -EnableFlowLog $true -StorageAccountId $storageAccountobjId -EnableTrafficAnalytics -Workspace $logAnalytics -FormatType Json -FormatVersion 2
          }
          catch {
            "$_"
          }
        }                     
      }                             
    }
  }
}
catch {
  "Fail to run runbook with error $_"
}