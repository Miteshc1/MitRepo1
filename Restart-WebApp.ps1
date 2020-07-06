# This automation runbook will restart a web app or slot.  Please pass in Slot or App to determine which level you want to restart.
# This Automation "PowerShell" runbook (Not PowerShell Workflow) can be used to set up the base Automation Runbook
# Pass in a Subscription Name and it will list all the Resource Groups.
# Use this to test your Automation account is setup properly and the runbook is properly formatted.
# This runbook uses the AZURERUNASACCOUNT
# Another runbook will use a Credential from the Azure Automation Account which is an Azure AD Identity
# Created by Mitesh Chauhan
# Date 15th June 2020

# Test Slot $SlotName = "slotname"

param(
    [parameter(Mandatory=$true)]
    [String] $SubscriptionID = "SubID",
    
    [parameter(Mandatory=$true)]
    [String] $ResourcegroupName = "RG Name",

    [parameter(Mandatory=$true)]
    [String] $WebAppName = "WebApp NAme",

    [parameter(Mandatory=$false)]
    [String] $AppOrSlot = "Slot",

    [parameter(Mandatory=$false)]
    [String] $SlotName = $null
)

# Setup Connection with RunAs Account
$connection = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzAccount -ServicePrincipal -Tenant $connection.TenantID `
-ApplicationId $connection.ApplicationID -CertificateThumbprint $connection.CertificateThumbprint

# Switch to Subscription passed in
$context = Get-AzSubscription -SubscriptionId $SubscriptionID
Set-AzContext $context

If ($AppOrSlot -ieq "App")
{
    Write-Output "Checking Web App...  Web App : $WebAppName, RG : $ResourcegroupName, Slot Name : $SlotName..."
    # Check Web App exists
    $WebApp = Get-AzWebApp -ResourceGroupName $ResourcegroupName -Name $WebAppName
    If ($WebApp)
    {
        Write-Output "Restarting Web App... Web App : $WebAppName, RG : $ResourcegroupName"
        # Restart Web App
        Restart-AzWebApp -ResourceGroupName $ResourcegroupName -Name $WebAppName
    }
    else {
        Write-Output "Web App Not Found... Web App : $WebAppName, RG : $ResourcegroupName"
    }
}
elseif ($AppOrSlot -ieq "Slot") 
{
    Write-Output "Checking Web App Slot...  Web App : $WebAppName, RG : $ResourcegroupName, Slot Name : $SlotName..."
    # Check Web App Slot exists
    $Slot = Get-AzWebAppSlot -ResourceGroupName $ResourcegroupName -Name $WebAppName -Slot $SlotName
    If ($Slot)
        {
            Write-Output "Restarting Web App Slot... Web App : $WebAppName, RG : $ResourcegroupName, Slot Name : $SlotName..."
            # Restart Web App Slot
            Restart-AzWebAppSlot -ResourceGroupName $ResourcegroupName -Name $WebAppName -Slot $SlotName
        }
        else {
            Write-Output "Web App Slot Not Found... Web App : $WebAppName, RG : $ResourcegroupName, Slot Name : $SlotName..."
        }
}
else 
{
    Write-Output "Please enter App or Slot only in the ApporSlot variable. Default is App so no need to provide for App service"
}

