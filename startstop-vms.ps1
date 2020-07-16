<#

    .SYNOPSIS 
        Stops or starts all the Azure VMs in an array of subscriptions by autoshutdown/autostart tag name and timezone value

    .DESCRIPTION
        This runbooks stops or starts all of the virtual machines in the specified Subscriptions. 
        
    .PARAMETER Subscription
        Start or Stop = Action to take
        Timezone = Recommended zones CET (West Europe), CT (Central US Time), PST (Pacific Standard Time), EST Eastern Standard Time (US), SGT Singapore

    .REQUIREMENTS 
        This runbook will only run in an Azure Automation Account with the Az Modules installed. Automation Service Account must have at least VM Contributor or custom role on required subscriptions
    
    .NOTES
        AUTHOR: Mitesh Chauhan - 22/9/2019, Updated 14/10/2019
        Update : Mitesh Chauhan - 7/1/2020 - Added tenant ID, Cleaned up screen prints.
        Update : Mitesh Chauhan - 24/1/2020 - Fixed bugs with tennant ID, added more messaging and check for empty VMList.

        # For Testing 
        $cred = Get-credential
        Connect-azAccount -Credential $Cred
        $subscriptionIDs = @("1111-1111-2222-3333-4444")
        $StartorStop = "Start"

        $context = Get-AzSubscription -SubscriptionID $SubscriptionID
        Set-AzContext $context
        $Timezone = "GMT"
#>

param
    (
        #The name of the Automation Credential Asset this runbook will use to authenticate to Azure.
        [Parameter(Mandatory=$true)]
        [String] $StartorStop = "Stop",

        # E.g. WE, CDT, SGT, EST, PST
        [Parameter(Mandatory=$true)]
        [String] $TimeZone  = "CDT",

        [parameter(Mandatory=$false)]
        [bool]$Simulate = $false
    )

$connection = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzAccount -ServicePrincipal -Tenant $connection.TenantID `
-ApplicationId $connection.ApplicationID -CertificateThumbprint $connection.CertificateThumbprint

# Set subscriptions to loop through use "s and comma to add multiple subs
$subscriptionIDs = @("SubID")

Foreach($SubscriptionID in $subscriptionIDs)
{
$context = Get-AzSubscription -SubscriptionID $SubscriptionID -TenantId $TenantID
Set-AzContext $context
$SubName = $Context.Name

Get-Date
Write-Output "Subscription Context selected : $Subname"
Write-Output "Action Requested :  $StartorStop"
Write-Output "Timezone selected : $TimeZone"

If($StartorStop -ieq "Stop")
{
Write-Output "Getting VM List for $StartorStop Action"
$vmList =  (Get-AzResource -Tag @{Autoshutdown="$Timezone"} -ResourceType Microsoft.Compute/virtualMachines) | Select Name, resourcegroupName, tags 
$Vmlist  | Select name, resourcegroupName | ft
    If($vmList)
    {
        foreach ($VM in $vmlist)
        {
        $PowerState = (Get-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -Status -ErrorAction $ErrorActionPreference -WarningAction $WarningPreference).Statuses.Code[1]
        if ($PowerState -eq 'PowerState/deallocated')
            {
            $VM.Name + " is already shut down."
            }
        else
        {
            If($Simulate)
                {
                $VM.Name + " would have been shut down."
                }
            else
                {
                $VM.Name + " is being shut down."
                $VMState = (Stop-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -Force -ErrorAction $ErrorActionPreference -WarningAction $WarningPreference).IsSuccessStatusCode
                start-sleep -Seconds 60  					
                    if ($VMState -eq 'True')
                        {
                    $VM.Name + " Has been shut down successfully."
                        }
                    else
                        {
                    $VM.Name + " Has failed to shut down. Shutdown Status  = " + $VMState
                        }
                }
        }
        }
    }
        else 
        {
            Write-Output "No VMs Found with $StartorStop Tag applied in subscription $subname " 
        }
}
    elseif($StartorStop -ieq "Start")
    {
    Write-Output "Getting VM List for $StartorStop Action"
    $vmList =  (Get-AzResource -Tag @{Autostart="$Timezone"} -ResourceType Microsoft.Compute/virtualMachines) | Select Name, resourcegroupName, tags 
    $Vmlist  | Select name, resourcegroupName | ft

    If($vmList)
    {
        foreach ($VM in $vmlist)
            {
            $PowerState = (Get-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -Status -ErrorAction $ErrorActionPreference -WarningAction $WarningPreference).Statuses.Code[1]

                if ($PowerState -eq 'PowerState/running')
                {
                    $VM.Name + " is already running."
                }
                    else
                {
                    If($Simulate)
                    {
                    $VM.Name + " would have been started."
                    }
                    else
                    {
                        $VM.Name + " is being started."
                        $VMState = (Start-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -ErrorAction $ErrorActionPreference -WarningAction $WarningPreference).IsSuccessStatusCode
                        start-sleep -Seconds 60 					
                        if ($VMState -eq 'True')
                            {
                        $VM.Name + " Has been started successfully."
                            }
                        else
                            {
                        $VM.Name + " Has failed to start.  Status  = " + $VMState
                            }
                    }
                }
        }
    }
    else 
    {
        Write-Output "No VMs Found with $StartorStop Tag applied in subscription $subname " 
    }

    } # End of outer if statement
} # Subscription Loop

Write-output "Script complete"
