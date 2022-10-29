#!/usr/bin/env powershell

# Install-Module dbatools -force

if (Get-Module -ListAvailable -Name dbatools) {
  Write-Host "Module exists"
  import-module dbatools
}
else {
  Write-Host "Module does not exist - Install-Module dbatools -force"
}

$now = Get-Date -Format "MM-dd-yyyy-hh-mm"
$logFilePath = "sqlscan-$now.log"
$winServersCsv = "servers.csv"
$creds = Get-Credential -Message "Account with credentials on remote servers to check folder presence"

# You should not need to change after here
$delim = (Get-Culture).TextInfo.ListSeparator

if (Test-Path $logfilepath) {
  Remove-Item $logfilepath
}

# Start logging
Start-Transcript -Path $logfilepath

# ultimate blast
# Find-DbaInstance -DiscoveryType All

# Get server list - not from AD to keep control
$servers = Import-Csv -path $winServersCsv -Delimiter $delim

# Parse list
foreach ($server in $servers) {
  # Check if we can contact server
  if ((Test-Connection -ComputerName $server.Name -Quiet) -eq $true) {
    Write-Information  "OK - $($server.Name) is reachable"
    get-dbacomputersystem -ComputerName $server.name -Credential $creds

    $databases = Find-DbaInstance -ComputerName $server.Name | Get-DbaDatabase
    foreach ($database in $databases){
      $results = $database | Select-Object SqlInstance, Name, Status, RecoveryModel, SizeMB, Compatibility, Owner, LastFullBackup, LastDiffBackup, LastLogBackup
      $results | Format-Table -Wrap
        $database | Get-DbaSpConfigure
    }


  }
  else {
    Write-Warning  "WARN - $($server.Name) is NOT reachable"
  }

}
# stop logging
Stop-Transcript