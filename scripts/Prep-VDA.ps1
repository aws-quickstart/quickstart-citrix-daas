<#
.SYNOPSIS
    Prepares XD VDA for installation using CWC library

    Copyright (c) Citrix Systems, Inc. All Rights Reserved.
.DESCRIPTION
    
#>
[CmdletBinding()]
param(
    # [Parameter(Mandatory=$true)][string] $VDA_MediaName,
    # [Parameter(Mandatory=$true)][string] $VDA_MediaLocation,
    # [Parameter(Mandatory=$false)][string] $VDA_LocalMediaLocation = (Join-Path -Path $ENV:Temp -ChildPath "Citrix")
)

try {
    # Copy XD media locally
    # Write-Host "Copying XD Media locally"
    # cwcOS-Tools\Download-File -FileName $VDA_MediaName -Path $VDA_MediaLocation -ToFolder $VDA_LocalMediaLocation -verbose
	Start-Transcript -Path C:\cfn\log\Prep-VDA.ps1.txt -Append    
	
    Import-Module ServerManager
	Write-Host "Enabling RDS Server Role"
	Add-WindowsFeature RDS-RD-Server

	# Write-Host "Enabling Desktop Experience"
	# Install-WindowsFeature -Name Desktop-Experience

	Write-Host "Enabling Remote Assistance"
	Install-WindowsFeature -Name Remote-Assistance 

    # $driveLetter = cwcOS-Tools\Mount-Iso -IsoPath $VDA_MediaLocation\$VDA_MediaName -verbose

	### Install C++ libararies
	Write-Host "Installing Nuget"
	Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
	Write-Host "Installing VcRedist"
	Install-Module -Name VcRedist -Force # Reference: https://github.com/aaronparker/Install-VisualCRedistributables
	New-Item C:\Temp\VcRedist -ItemType Directory
	Get-VcList | Get-VcRedist -Path C:\Temp\VcRedist
	Get-VcList | Install-VcRedist -Path C:\Temp\VcRedist

	# # C++ 2005 Runtime
	# Write-Host "Installing C++ 2005 x86 ..."
	# Start-Process -FilePath (join-path $driveLetter "Support\VcRedist_2005\vcredist_x86.exe") -Wait -ArgumentList "/q"
	# Write-Host "Installing C++ 2005 x64 ..."
	# Start-Process -FilePath (join-path $driveLetter "Support\VcRedist_2005\vcredist_x64.exe") -Wait -ArgumentList "/q"
				
	# # C++ 2008 SP1 Runtime
	# Write-Host "Installing C++ 2008 x86 ..."
	# Start-Process -FilePath (join-path $driveLetter "Support\VcRedist_2008_SP1\vcredist_x86.exe") -Wait -ArgumentList "/q"
		
	# Write-Host "Installing C++ 2008 x64 ..."
	# Start-Process -FilePath (join-path $driveLetter "Support\VcRedist_2008_SP1\vcredist_x64.exe") -Wait -ArgumentList "/q"
		
	# # C++ 2010 Runtime
	# Write-Host "Installing C++ 2010 x86 ..."
	# Start-Process -FilePath (join-path $driveLetter "Support\VcRedist_2010_RTM\vcredist_x86.exe") -Wait -ArgumentList "/q"

	# Write-Host "Installing C++ 2010 x64 ..."
	# Start-Process -FilePath (join-path $driveLetter "Support\VcRedist_2010_RTM\vcredist_x64.exe") -Wait -ArgumentList "/q"

    # cwcOS-Tools\Dismount-Iso $driveLetter -verbose
}
catch {
    $Error[0]
    exit 1
}