## Runbook to set database diagnostics on DBs that are not logging data to Log Analytics
# Pass in the ResourceID of Log Analytics Workspace can use Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $LogAnalyticsWorkspaceName to get this.
# Created by Mitesh Chauhan Jan 2020

param(
    [parameter(Mandatory=$false)]
	[Array] $SubscriptionNames          = @("Subname1","Subname2"),
    [parameter(Mandatory=$false)]
	[String] $LogAnalyticsWorkspaceID   = "/subscriptions/xxxxxxxxx-xxxx-xxxx-xxxx-xxxxx/resourcegroups/rgname/providers/microsoft.operationalinsights/workspaces/workspacename"
    )

$connection = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzAccount -ServicePrincipal -Tenant $connection.TenantID -ApplicationId $connection.ApplicationID -CertificateThumbprint $connection.CertificateThumbprint

$WarningPreference = 'SilentlyContinue'

# Retrieve all SQL Servers in subscriptions specified in the parameters
Foreach($SubscriptionName in $SubscriptionNames)
{
    # Switch context to subscription
    $context = Get-AzSubscription -SubscriptionName $SubscriptionName
    Set-AzContext $context
    $SQLServers = Get-AzSqlServer

    # Loop through all SQL Servers
    Foreach($SQLServer in $SQLServers)
        {
        $SQLServer.ServerName
        $Databases = Get-AzSqlDatabase -ServerName $SQLServer.ServerName -ResourceGroupName $SQLServer.ResourceGroupName

        # Loop through all databases
        Foreach($Database in $Databases)
        {
        # Check if Database already has diagnostics enabled
        $Diags = Get-AzDiagnosticSetting -ResourceId $Database.ResourceId | Select-object name

            # If not already enabled and database is NOT the master database then set diagnostic settings
            IF(!$Diags -and $Database.DatabaseName -ine "Master")
            {
            $Database.DatabaseName
            $DiagnosticName = $Database.DatabaseName+"-Diags"
                If ($Simulate)
                {
                    Write-Output "Would have set diagnostics on " $Database.DatabaseName
                }
                else 
                {
                     Write-Output "Setting diagnostics on " $Database.DatabaseName
                     Set-AzDiagnosticSetting -Name $DiagnosticName -ResourceId $Database.ResourceId -Enabled $true -WorkspaceId $LogAnalyticsWorkSpace.ResourceId                
                }
            }
            else 
            {
                    Write-Output "Diagnostics already set on"  $Database.DatabaseName   
            }
        } # End of DB For Loop
    } # End of SQL Server For Loop
} # End of Subscription Loop