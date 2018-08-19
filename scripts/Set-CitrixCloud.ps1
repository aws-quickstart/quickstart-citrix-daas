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

    [Parameter(Mandatory=$false)]
    [string] $CtxZoneName = "AWS-QuickStart", 

    [Parameter(Mandatory=$false)]
    [string] $CtxHostingConnectionName = "AWS-QuickStart", 

    [Parameter(Mandatory=$false)]
    [string] $CtxCatalogName = "CAT-AWS-QuickStart",
    
    [Parameter(Mandatory=$false)]
    [string] $CtxDeliveryGroupName = "DG-AWS-QuickStart",

    [Switch]$AddCurrentMachine
)

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
    $CtxZone = Get-ConfigZone -Name $CtxResourceLocationName;

    # Create new hosting connection
    Write-Host "Create new hosting connection"
    $m_HypervisorConnectionObject = New-Item -Path xdhyp:\Connections -Name $CtxHostingConnectionName -ConnectionType "AWS" -HypervisorAddress @("https://ec2.amazonaws.com") -UserName $AWSAPIKey -Password $AWSSecretKey -ZoneUid $CtxZone.Uid -Persist 
    $m_HypervisorConnection = New-BrokerHypervisorConnection -HypHypervisorConnectionUid $m_HypervisorConnectionObject.HypervisorConnectionUid

    # Create new catalog. As machines here are unmanaged, MachinesArePhysical is set to $True. 
    Write-Host "Create new machine catalog"
    $m_CAT = New-BrokerCatalog  -AllocationType "Random" -Description "" -IsRemotePC $False -MachinesArePhysical $True -MinimumFunctionalLevel "L7_9" -Name $CtxCatalogName -PersistUserChanges "OnLocal" -ProvisioningType "Manual" -Scope @() -SessionSupport "MultiSession" -ZoneUid $CtxZone.Uid

    # Create new delivery group
    Write-Host "Create new delivery group"
    $m_DG = New-BrokerDesktopGroup  -ColorDepth "TwentyFourBit" -DeliveryType "DesktopsAndApps" -DesktopKind "Shared" -InMaintenanceMode $False -IsRemotePC $False -MinimumFunctionalLevel "L7_9" -Name $CtxDeliveryGroupName -OffPeakBufferSizePercent 10 -PeakBufferSizePercent 10 -PublishedName $CtxDeliveryGroupName -Scope @() -SecureIcaRequired $False -SessionSupport "MultiSession" -ShutdownDesktopsAfterUse $False -TimeZone "UTC"

    # Add current machine to created delivery group. 
    If ($AddCurrentMachine) {
        Write-Host "Add current machine to machine catalog and delivery group"
    # This could be also tied up to hypervisor connection to support power management, however that is complicated to implement. Two parameters would need to be added: -HypervisorConnectionUid $m_HypervisorConnection.Uid;  and -HostedMachineId. HostedMachineId is specific to hypervisor (for AWS, it's using format like i-0a100f4a1c1fc1d29) and there is no simple method how to link current machine with it's ID. 
    # The only method (aside from some AWS tooling or cmdlets) would be to parse the output from 'Get-ChildItem XDHyp:\Connections\AWS-QuickStart -Recurse', which is slow and again needs to have link between AWS and domain name of machine. 
    $m_CurrentMachine = New-BrokerMachine -CatalogUid $m_CAT.Uid -MachineName "$((Get-WmiObject Win32_NTDomain).DomainName)\$([Environment]::MachineName)"; 
    Add-BrokerMachine -InputObject $m_CurrentMachine -DesktopGroup $m_DG; 
    }

    # Create entitlements
    Write-Host "Create entitlement rules"
    New-BrokerAppEntitlementPolicyRule -DesktopGroupUid $m_DG.Uid -Enabled $True -IncludedUserFilterEnabled $False -Name "$($CtxDeliveryGroupName)_1"
    New-BrokerEntitlementPolicyRule -DesktopGroupUid $m_DG.Uid -Enabled $True -IncludedUserFilterEnabled $False -Name "$($CtxDeliveryGroupName)_1" -PublishedName $CtxDeliveryGroupName

    # Create access rules
    Write-Host "Create access rules"
    New-BrokerAccessPolicyRule -AllowedConnections "NotViaAG" -AllowedProtocols @("HDX","RDP") -AllowedUsers "AnyAuthenticated" -AllowRestart $True -DesktopGroupUid $m_DG.Uid -Enabled $True -IncludedSmartAccessFilterEnabled $True -Name "$($m_DG.Name)_Direct" -IncludedUserFilterEnabled $True;
    New-BrokerAccessPolicyRule -AllowedConnections "ViaAG" -AllowedProtocols @("HDX","RDP") -AllowedUsers "AnyAuthenticated" -AllowRestart $True -DesktopGroupUid $m_DG.Uid -Enabled $True -IncludedSmartAccessFilterEnabled $True -IncludedSmartAccessTags @() -Name "$($m_DG.Name)_AG" -IncludedUserFilterEnabled $True;

    # Publish few applications
    Write-Host "Publish applications"
    $instanceId = Invoke-WebRequest -Uri http://169.254.169.254/latest/meta-data/instance-id    
    [Array]$m_PublishedApps = @("C:\Program Files\Internet Explorer\iexplore.exe", "C:\Windows\System32\notepad.exe"); 

    ForEach ($m_PAPath in $m_PublishedApps) {
        $m_FileDetails = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($m_PAPath); 
        Write-Host "Publishing $($m_FileDetails.FileDescription)"; 
        $m_FileIcon = Get-BrokerIcon -FileName $m_PAPath -index 0;
        $m_CtxIcon = New-BrokerIcon -EncodedIconData $m_FileIcon.EncodedIconData;
        $m_AppName = -join($m_FileDetails.FileDescription,"_",$instanceId)

        New-BrokerApplication -ApplicationType "HostedOnDesktop" -CommandLineArguments "" -CommandLineExecutable $m_PAPath -CpuPriorityLevel "Normal" -DesktopGroup $m_DG.Uid -Enabled $True -IgnoreUserHomeZone $False -MaxPerUserInstances 0 -MaxTotalInstances 0 -Name $m_AppName -Priority 0 -PublishedName $m_FileDetails.FileDescription -SecureCmdLineArgumentsEnabled $True -ShortcutAddedToDesktop $False -ShortcutAddedToStartMenu $False -UserFilterEnabled $False -Visible $True -WaitForPrinterCreation $False -IconUid $m_CtxIcon.Uid
    }

}
catch {
    $_ | Write-AWSQuickStartException
}


