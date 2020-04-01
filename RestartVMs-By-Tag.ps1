# This runbook will restart VMs in a resource group where tag = "Restart on the VMs that need restarting.
# Pass in a subscription ID and optional Resource Group name and schedule job.  If no RG is passed in the whole subscription will be evaluated.
# Default schedule is daily if VMs have Restart Daily tag and value.
# To restart weekly, tag VMs with restart Weeekly and schedule this job weekly with Weekly value for Restart flag.

# $Cred = Get-Credential
# $SubscriptionID = "SubID"
# $ResourceGroupName = "RG-Name"
# Connect-AzAccount -Credential $Cred

	param
        (
    	#The name of the Automation Credential Asset this runbook will use to authenticate to Azure.
        [Parameter(Mandatory=$true)]
        [String] $SubscriptionID  = "SubID",

        [Parameter(Mandatory=$false)]
        [String] $ResourceGroupName = $null,

        [Parameter(Mandatory=$false)]
        [String] $Schedule = "Daily"
        )

      # Log in with Automation Credential
      $connection = Get-AutomationConnection -Name AzureRunAsConnection
      Connect-AzAccount -ServicePrincipal -Tenant $connection.TenantID `
      -ApplicationId $connection.ApplicationID -CertificateThumbprint $connection.CertificateThumbprint

      # Set subscription
      $context = Get-AzSubscription -SubscriptionID $SubscriptionID
      Set-AzContext $context
      Write-Output "Context Selected" $context
      Write-Output "ResourceGroup Selected" $ResourceGroupName

      # Print Start time
      $StartTime = Get-Date
      Write-output "Resource group is set to : $ResourceGroupName "
      Write-output "Schedule is set to : $Schedule "  

      If(!$ResourceGroupName )
      {
      Write-Output "No ResourceGroup Provided - Scope = Subscription : $context.Name"

      $VMlist = Get-AzResource -TagName "Restart" -ResourceType Microsoft.Compute/virtualMachines | where { $_.Tags[‘Restart’] -ieq $schedule } | Select Name, Location, ResourceGroupName, tags
      Write-Output "Restart VM list :" $vmlist
      }
      else
      {
      $VMlist = Get-AzResource -TagName "Restart" -ResourceType Microsoft.Compute/virtualMachines | where { $_.Tags[‘Restart’] -ieq $schedule } | Select Name, Location, ResourceGroupName, tags | where {$_.ResourceGroupName -ieq $ResourceGroupName}
      Write-Output "Restart VM list :" $vmlist
      }

      Foreach($VM in $VMList)
      {
        $PowerState = (Get-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -Status -ErrorAction $ErrorActionPreference -WarningAction $WarningPreference).Statuses.Code[1]

        if ($PowerState -eq 'PowerState/running')
            {
            $VM.Name + " is running. Restarting"
            $VM.Name + " is being restarted."
            $RestartState = (Restart-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -ErrorAction $ErrorActionPreference -WarningAction $WarningPreference).IsSuccessStatusCode
            start-sleep -Seconds 60 					
            }
             elseif ($PowerState -eq 'PowerState/deallocated')
            {
             $VM.Name + " Was not running and will be started up now.  Current Status  = " + $PowerState
              Start-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.name -ErrorAction $ErrorActionPreference -WarningAction $WarningPreference
            }
              else
            {
             # Do nothing here
            }
        # Check Powerstate now
        start-sleep -Seconds 60
        $PowerState = (Get-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -Status -ErrorAction $ErrorActionPreference -WarningAction $WarningPreference).Statuses.Code[1]

        $VM.Name + " Status at end of script run time : " + $PowerState
      }
     
     $Endtime = Get-Date
     $TimeTaken = NEW-TIMESPAN –Start $StartTime –End $Endtime | Select Minutes, Seconds
     $TimeTaken