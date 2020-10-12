<#
.SYNOPSIS
Gets list of installed software and their version. Admin rights are required.
Duplicate Name/Version combinations are discarded.
Edit $exclude to exclude certain items from result.

.PARAMETER ComputerName
Remote computer name. Leave empty if querying local PC

.EXAMPLE
.\Get-InstalledSoftware.ps1 -ComputerName MYCOMPUTER
#>

param (
    [String]$ComputerName
    )

#Software that you want excluded from the report (regex)
$exclude = @(
    "\(KB",
    "Microsoft Exchange Client Language Pack",
    "Microsoft Exchange Server Language Pack"
)

$sb32 = {
    Get-ChildItem -Path HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | 
    Get-ItemProperty | Select-Object -Property DisplayName, DisplayVersion, Publisher, InstallDate | Where DisplayName 
}

$sb64 = {
    Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | 
    Get-ItemProperty | Select-Object -Property DisplayName, DisplayVersion, Publisher, InstallDate | Where DisplayName  
}
#Get full list of installed SW (32 and 64 bit)
#WMI is too slow, going directly to registry instead
if ($ComputerName) {
    $Dump32bit = Invoke-Command -ComputerName $ComputerName -ScriptBlock $sb32
    $Dump64bit = Invoke-Command -ComputerName $ComputerName -ScriptBlock $sb64
        
} else {
    $Dump32bit = Invoke-Command -ScriptBlock $sb32
    $Dump64bit = Invoke-Command -ScriptBlock $sb64
}
$SoftwareDump = ($Dump32bit + $Dump64bit)

$installedSoftware = @()

$exclude = ($exclude -join '|')

#remove excluded items, remove duplicate items and sort output
$installedSoftware = $SoftwareDump | ? displayName -notmatch $exclude |
    select -Property DisplayName, DisplayVersion, Publisher, InstallDate -Unique | Sort-Object -Property DisplayName

$installedSoftware
