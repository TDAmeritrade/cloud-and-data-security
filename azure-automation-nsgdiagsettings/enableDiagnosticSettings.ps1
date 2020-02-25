$connection = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzAccount -ServicePrincipal -Tenant $connection.TenantID -ApplicationID $connection.ApplicationID -CertificateThumbprint $connection.CertificateThumbprint  

$logAnalyticsWorkspaceName = ""
$logAnalyticsResourceGroupName = ""
$logAnalyticsSubscriptionId = ""

Select-AzSubscription -Subscription $logAnalyticsSubscriptionId

try {
  $logAnalytics = Get-AzOperationalInsightsWorkspace -ResourceGroupName $logAnalyticsResourceGroupName -Name $logAnalyticsWorkspaceName 
  $workspaceId = $logAnalytics.ResourceId
  Write-Host "$workspaceId"
}
catch {
  Write-Host "Error: $_"
}

if ($logAnalytics) {
  $subscriptions = Get-AzSubscription 
  try {  
    foreach ($subscription in $subscriptions) {
      Select-AzSubscription -Subscription $subscription | Out-Null
      $resourceGroups = Get-AzResourceGroup
      Write-host  "Working with subscription $($subscription) and Resource group $($resourceGroups.ResourceGroupName)" -ForegroundColor DarkGreen
      foreach ($resourceGroup in $resourceGroups) {
        $resources = Get-AzResource -ResourceGroupName $resourceGroup.ResourceGroupName
        foreach ($resource in $resources) {                              
          if (!(Get-AzDiagnosticSetting -ResourceId $resource.ResourceId -ErrorAction SilentlyContinue)) {
            try {
              if ($resource.ResourceType -eq "Microsoft.Sql/Servers/databases") {
                $categories="SQLInsights","AutomaticTuning","QueryStoreRuntimeStatistics","Errors","DatabaseWaitStatistics","Timeouts","Blocks","Deadlocks","Audit","SQLSecurityAuditEvents"
                Set-AzDiagnosticSetting -ResourceId $resource.resourceId -WorkspaceId $workspaceId -Enable $True -Name "$(($resource.name).split("/")[1])_Diagnostic" -RetentionEnabled $true -RetentionInDays 90 -MetricCategory AllMetrics -Categories $categories -ErrorAction SilentlyContinue
              }
              else {
                Set-AzDiagnosticSetting -ResourceId $resource.resourceId -WorkspaceId $workspaceId -Enable $True -Name "$($resource.name)_Diagnostic" -RetentionEnabled $true -RetentionInDays 90 -ErrorAction SilentlyContinue
              }
            }
            catch {
            }
          }

        }
      }
                        
    }
                      
  }
  catch {
    "Fail to run runbook with error $_"
  }
}
