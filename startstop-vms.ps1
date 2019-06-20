<#

    .SYNOPSIS 
        Stops or starts all the Azure VMs in a specified subscription by autoshutdown tag name and timezone value
        Schedule it to run and pass in the Timezone you want to evaluate.

    .DESCRIPTION
        This sample runbooks stops or starts all of the virtual machines in the specified Subscription. 
        For more information about how this runbook authenticates to your Azure subscription, see the
        Microsoft documentation here: http://aka.ms/fxu3mn. 

    .PARAMETER Subscription
        Name of the Azure Subscription containing the VMs to be stopped or started.
        Start or Stop = Action to take
        Timezone = Recommended zones CET (West Europe), CT (Central US Time), PST (Pacific Standard Time), EST Eastern Standard Time (US), SGT Singapore

    .REQUIREMENTS 
        This runbook will only run in an Azure Automation Account with the Az Modules installed.
    
    .NOTES
        AUTHOR: Mitesh Chauhan - LA NET Limited 19/6/2019
#>

	param
        (
    	#The name of the Automation Credential Asset this runbook will use to authenticate to Azure.
        [Parameter(Mandatory=$true)]
        [String] $SubscriptionName  = "Subname",

        [Parameter(Mandatory=$true)]
        [String] $StartorStop = "Start",

        [Parameter(Mandatory=$true)]
        [String] $TimeZone  = "TestCentralUS",

        [parameter(Mandatory=$false)]
        [bool]$Simulate = $false

        )

        $connection = Get-AutomationConnection -Name AzureRunAsConnection
        Connect-AzAccount -ServicePrincipal -Tenant $connection.TenantID `
        -ApplicationId $connection.ApplicationID -CertificateThumbprint $connection.CertificateThumbprint
    
        $context = Get-AzSubscription -SubscriptionName $SubscriptionName
        Set-AzContext $context

        Write-Output "Subscription selected : $SubscriptionName"
        Write-Output "Action Requested : $StartorStop"
        Write-Output "Timezone selected : $TimeZone"
        
If($StartorStop -ieq "Stop")
    {
        Write-Output "Getting VM List for $StartorStop Action"
        $vmList = Get-AzResource -TagName "AutoShutdown" -ResourceType Microsoft.Compute/virtualMachines | where { $_.Tags[‘AutoShutdown’] -ieq "$TimeZone" } | Select Name, resourcegroupName, tags 
        $Vmlist  | Select name, resourcegroup
            foreach ($VM in $vmlist)
            {
            $PowerState = (Get-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -Status -ErrorAction $ErrorActionPreference -WarningAction $WarningPreference).Statuses.Code[1]
             if ($PowerState -eq 'PowerState/deallocated')
                {
                $VM.Name + " is already shut down."
                }
            else
                {
                $VM.Name + " is being shut down."
                $VMState = (Stop-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -Force -ErrorAction $ErrorActionPreference -WarningAction $WarningPreference).IsSuccessStatusCode
                start-sleep -Seconds 90  					
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
elseif($StartorStop -ieq "Start")
    {
        Write-Output "Getting VM List for $StartorStop Action"
        $vmList = Get-AzResource -TagName "AutoStart" -ResourceType Microsoft.Compute/virtualMachines | where { $_.Tags[‘AutoStart’] -ieq "$TimeZone" } | Select Name, ResourceGroupName, tags 
        $Vmlist  | Select name, ResourceGroupName
    foreach ($VM in $vmlist)
            {
                $PowerState = (Get-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -Status -ErrorAction $ErrorActionPreference -WarningAction $WarningPreference).Statuses.Code[1]

                  if ($PowerState -eq 'PowerState/running')
                   {
                    $VM.Name + " is already running."
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
Write-output "Script complete"
