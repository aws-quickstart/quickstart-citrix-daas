[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [String] $CtxCustomerId, 

    [Parameter(Mandatory=$true)]
    [String] $CtxClientID,

    [Parameter(Mandatory=$true)]
    [String] $CtxClientSecret,

    [Parameter(Mandatory=$false)]
    [string] $CtxResourceLocationName = "AWS-QuickStart", 

    [Parameter(Mandatory=$true)]
    [string] $AWSAPIKey, 

    [Parameter(Mandatory=$true)]
    [string] $AWSSecretKey, 

    [Parameter(Mandatory=$true)]
    [string] $AWSRegion, 

    [Parameter(Mandatory=$false)]
    [string] $CtxZoneName = "AWS-QuickStart", 

    [Parameter(Mandatory=$false)]
    [string] $CtxHostingConnectionName = "AWS-QuickStart", 

    [Parameter(Mandatory=$false)]
    [string] $CtxCatalogName = "CAT-AWS-QuickStart",
    
    [Parameter(Mandatory=$false)]
    [string] $CtxDeliveryGroupName = "DG-AWS-QuickStart",

    [Parameter(Mandatory=$false)]
    [string] $QSDeploymentID = "0",

    [Switch]$AddCurrentMachine
)

<#
This function can be used to pass a ScriptBlock (closure) to be executed and returned.
The operation retried a few times on failure, and if the maximum threshold is surpassed, the operation fails completely.
Params:
    Command         - The ScriptBlock to be executed
    RetryDelay      - Number (in seconds) to wait between retries
                      (default: 5)
    MaxRetries      - Number of times to retry before accepting failure
                      (default: 5)
    VerboseOutput   - More info about internal processing
                      (default: false)
Examples:
Execute-With-Retry { $connection.Open() }
$result = Execute-With-Retry -RetryDelay 1 -MaxRetries 2 { $command.ExecuteReader() }
#>

function Execute-With-Retry {
    [CmdletBinding()]
    param(    
    [Parameter(ValueFromPipeline,Mandatory)]
    $Command,    
    $RetryDelay = 30,
    $MaxRetries = 10,
    $VerboseOutput = $true
    )
    
    $currentRetry = 0
    $success = $false
    $cmd = $Command.ToString()

    do {
        try
        {
            $result = & $Command
            $success = $true
            if ($VerboseOutput -eq $true) {
                write-host "Successfully executed $cmd"
            }

            return $result
            
        }
        catch [System.Exception]
        {
            $currentRetry = $currentRetry + 1
                        
            if ($VerboseOutput -eq $true) {
                write-host "Failed to execute $cmd]: " + $_.Exception.Message
            }
            
            if ($currentRetry -gt $MaxRetries) {                
                throw "Could not execute [$cmd]. The error: " + $_.Exception.ToString()
            } else {
                if ($VerboseOutput -eq $true) {
                    write-host "Waiting $RetryDelay second(s) before attempt #$currentRetry of [$cmd]"
                }
                Start-Sleep -s $RetryDelay
            }
        }
    } while (!$success);
}

try {

    Start-Transcript -Path C:\cfn\log\Set-CitrixCloud.ps1.txt -Append   

    # Error handling
    $Global:ErrorActionPreference = "Stop";

    # Check if user is administrator
    Write-Host "Checking permissions"
    If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Throw "You must be administrator in order to execute this script"
    }

    # Download Citrix PowerShell SDK
    Write-Host "Downloading Citrix PowerShell SDK";
    $m_SDKTempFile = $(New-TemporaryFile).FullName + ".exe";
    $m_SDKURL = "http://download.apps.cloud.com/CitrixPoshSdk.exe";
    (New-Object System.Net.WebClient).DownloadFile($m_SDKURL, $m_SDKTempFile);

    # Install Citrix PowerShell SDK
    Write-Host "Installing Citrix PowerShell SDK"
    Start-Process $m_SDKTempFile "/q" -Wait

    # Cleanup
    Write-Host "Cleaning up..."
    Remove-Item $m_SDKTempFile

    # Initialize Citrix Cloud SDK
    Write-Host "Initializing SDK"
    Add-PSSnapin Citrix*

    # Configure authentication
    Write-Host "Citrix Cloud authentication"
    Set-XDCredentials -CustomerId $CtxCustomerId -ProfileType CloudAPI -APIKey $CtxClientId -SecretKey $CtxClientSecret;

    # Retrieve zone
    Write-Host "Retrieve current zone"
    $CtxZone = Execute-With-Retry {Get-ConfigZone -Name "$CtxResourceLocationName-$QSDeploymentID"};
    write-host CtxZone UID: $CtxZone.uid

    # Create new hosting connection
    Write-Host "Create new hosting connection in AWS Region $AWSRegion"
    $m_HypervisorConnectionObject = New-Item -Path xdhyp:\Connections -Name "$CtxHostingConnectionName-$QSDeploymentID" -ConnectionType "AWS" -HypervisorAddress @("https://ec2.$($AWSRegion).amazonaws.com") -UserName $AWSAPIKey -Password $AWSSecretKey -ZoneUid $CtxZone.Uid -Persist 
    $m_HypervisorConnection = New-BrokerHypervisorConnection -HypHypervisorConnectionUid $m_HypervisorConnectionObject.HypervisorConnectionUid

    # Create new hosting unit
    # Retrieve VPC ID: 
    $m_MAC = Invoke-RestMethod http://169.254.169.254/latest/meta-data/network/interfaces/macs | Select-Object -First 1; 
    $m_VPC_ID = Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/network/interfaces/macs/$($m_Mac)vpc-id;
    $m_Subnet_ID = Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/network/interfaces/macs/$($m_Mac)subnet-id;
    $m_AvailabilityZoneName = Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/placement/availability-zone;
    $m_Instance_ID = Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/instance-id; 

    $m_VPC_Obj = Get-ChildItem "XDHyp:\Connections\$($m_HypervisorConnection.Name)" | Where-Object {$_.ObjectType -eq "VirtualPrivateCloud" -and $_.ID -eq $m_VPC_ID};
    $m_AvailabilityZone_Obj = Get-Item "$($m_VPC_Obj.FullPath)\$m_AvailabilityZoneName.availabilityzone"; 
    $m_Subnet_Obj = Get-ChildItem $m_AvailabilityZone_Obj.FullPath | Where-Object {$_.ObjectType -eq "Network" -and $_.ID -eq $m_Subnet_ID};

    New-Item -AvailabilityZonePath @($m_AvailabilityZone_Obj.FullPath) -HypervisorConnectionName $m_HypervisorConnection.Name -NetworkPath @($m_Subnet_Obj.FullPath) -Path @("XDHyp:\HostingUnits\VDA-Network-$($QSDeploymentID)") -PersonalvDiskStoragePath @() -RootPath $m_VPC_Obj.FullPath -StoragePath @();

    # Create new catalog. As machines here are unmanaged, MachinesArePhysical is set to $True. 
    Write-Host "Create new machine catalog"
    $m_CAT = New-BrokerCatalog  -AllocationType "Random" -Description "Created by AWS QuickStart - Deployment ID $QSDeploymentID" -IsRemotePC $False -MachinesArePhysical $False -MinimumFunctionalLevel "L7_9" -Name "$CtxCatalogName-$QSDeploymentID" -PersistUserChanges "OnLocal" -ProvisioningType "Manual" -Scope @() -SessionSupport "MultiSession" -ZoneUid $CtxZone.Uid

    # Create new delivery group
    Write-Host "Create new delivery group"
    $m_DG = New-BrokerDesktopGroup -Description "Created by AWS QuickStart - Deployment ID $QSDeploymentID" -ColorDepth "TwentyFourBit" -DeliveryType "DesktopsAndApps" -DesktopKind "Shared" -InMaintenanceMode $False -IsRemotePC $False -MinimumFunctionalLevel "L7_9" -Name "$CtxDeliveryGroupName-$QSDeploymentID" -OffPeakBufferSizePercent 10 -PeakBufferSizePercent 10 -PublishedName "AWS QuickStart Desktop $QSDeploymentID" -Scope @() -SecureIcaRequired $False -SessionSupport "MultiSession" -ShutdownDesktopsAfterUse $False -TimeZone "UTC"

    # Add current machine to created delivery group. 
    If ($AddCurrentMachine) {
        Write-Host "Add current machine to machine catalog and delivery group"
    # This could be also tied up to hypervisor connection to support power management, however that is complicated to implement. Two parameters would need to be added: -HypervisorConnectionUid $m_HypervisorConnection.Uid;  and -HostedMachineId. HostedMachineId is specific to hypervisor (for AWS, it's using format like i-0a100f4a1c1fc1d29) and there is no simple method how to link current machine with it's ID. 
    # The only method (aside from some AWS tooling or cmdlets) would be to parse the output from 'Get-ChildItem XDHyp:\Connections\AWS-QuickStart -Recurse', which is slow and again needs to have link between AWS and domain name of machine. 
    $m_CurrentMachine = New-BrokerMachine -CatalogUid $m_CAT.Uid -MachineName "$((Get-WmiObject Win32_NTDomain).DomainName)\$([Environment]::MachineName)" -HypervisorConnectionUid $m_HypervisorConnection.Uid -HostedMachineId $m_Instance_ID; 
    Add-BrokerMachine -InputObject $m_CurrentMachine -DesktopGroup $m_DG; 
    }

    # Create entitlements
    Write-Host "Create entitlement rules"
    New-BrokerAppEntitlementPolicyRule -DesktopGroupUid $m_DG.Uid -Enabled $True -IncludedUserFilterEnabled $False -Name "$("$CtxDeliveryGroupName-$QSDeploymentID")_1"
    New-BrokerEntitlementPolicyRule -DesktopGroupUid $m_DG.Uid -Enabled $True -IncludedUserFilterEnabled $False -Name "$("$CtxDeliveryGroupName-$QSDeploymentID")_1" -PublishedName "AWS QuickStart Desktop $QSDeploymentID"

    # Create access rules
    Write-Host "Create access rules"
    New-BrokerAccessPolicyRule -AllowedConnections "NotViaAG" -AllowedProtocols @("HDX","RDP") -AllowedUsers "AnyAuthenticated" -AllowRestart $True -DesktopGroupUid $m_DG.Uid -Enabled $True -IncludedSmartAccessFilterEnabled $True -Name "$($m_DG.Name)_Direct" -IncludedUserFilterEnabled $True;
    New-BrokerAccessPolicyRule -AllowedConnections "ViaAG" -AllowedProtocols @("HDX","RDP") -AllowedUsers "AnyAuthenticated" -AllowRestart $True -DesktopGroupUid $m_DG.Uid -Enabled $True -IncludedSmartAccessFilterEnabled $True -IncludedSmartAccessTags @() -Name "$($m_DG.Name)_AG" -IncludedUserFilterEnabled $True;

    # Publish few applications
    Write-Host "Publish applications"
    # $instanceId = Invoke-WebRequest -Uri http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing
    [Array]$m_PublishedApps = @("C:\Program Files\Internet Explorer\iexplore.exe", "C:\Windows\System32\notepad.exe"); 

    ForEach ($m_PAPath in $m_PublishedApps) {
        $m_FileDetails = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($m_PAPath); 
        Write-Host "Publishing $($m_FileDetails.FileDescription)"; 
        $m_FileIcon = Get-BrokerIcon -FileName $m_PAPath -index 0;
        $m_CtxIcon = New-BrokerIcon -EncodedIconData $m_FileIcon.EncodedIconData;
        # $m_AppName = -join($m_FileDetails.FileDescription,"_",$instanceId)
        $m_AppName = -join($m_FileDetails.FileDescription,"-",$QSDeploymentID)

        New-BrokerApplication -ApplicationType "HostedOnDesktop" -CommandLineArguments "" -CommandLineExecutable $m_PAPath -CpuPriorityLevel "Normal" -DesktopGroup $m_DG.Uid -Enabled $True -IgnoreUserHomeZone $False -MaxPerUserInstances 0 -MaxTotalInstances 0 -Name $m_AppName -Priority 0 -PublishedName $m_FileDetails.FileDescription -SecureCmdLineArgumentsEnabled $True -ShortcutAddedToDesktop $False -ShortcutAddedToStartMenu $False -UserFilterEnabled $False -Visible $True -WaitForPrinterCreation $False -IconUid $m_CtxIcon.Uid
    }

}
catch {
    $_ | Write-AWSQuickStartException
}


