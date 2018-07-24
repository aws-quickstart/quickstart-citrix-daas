### Install C++ libararies
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name VcRedist -Force # Reference: https://github.com/aaronparker/Install-VisualCRedistributables
New-Item C:\Temp\VcRedist -ItemType Directory
Get-VcList | Get-VcRedist -Path C:\Temp\VcRedist
Get-VcList | Install-VcRedist -Path C:\Temp\VcRedist

### Install Windows Server Features
Import-Module ServerManager
Add-WindowsFeature -Name Remote-Assistance,Remote-Desktop-Services,RDS-RD-Server -Restart