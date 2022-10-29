#!/usr/bin/env powershell

$now = Get-Date -Format "MM-dd-yyyy-hh-mm"
$logFilePath = "sqlscan-$now.log"
$winServersCsv = "servers.csv"
$sqlServersCsv = "sqlservers.csv"
$sqlFolder = 'C:\Program Files\Microsoft SQL Server'
$creds = Get-Credential -Message "Account with credentials on remote servers to check folder presence"


# You should not need to change after here
$sqls = @()
$delim = (Get-Culture).TextInfo.ListSeparator

if (Test-Path $logfilepath) {
  Remove-Item $logfilepath
}

# Start logging
Start-Transcript -Path $logfilepath

# Get server list - not from AD to keep control
$servers = Import-Csv -path $winServersCsv -Delimiter $delim

# Parse list
foreach ($server in $servers) {
  # Check if we can contact server
  if ((Test-Connection -ComputerName $server.Name -Quiet) -eq $true) {
    Write-Information  "OK - $($server.Name) is reachable"
    # make the remote call
    $test = Invoke-Command -ScriptBlock { Test-Path $sqlFolder } -ComputerName $server.Name -Credential $creds
    if ($test) {
      Write-Information "OK - Folder $sqlFolder is present"
      $sqls.Add( $server)
    }
    else {
      Write-Information "OK - Folder $sqlFolder is NOT present"
    }

    # Invoke-Command -ComputerName $server -ScriptBlock {
    #   if (New-PSDrive -Name X -PSProvider FileSystem -Root $sqlFolder -ErrorAction Ignore) {
    #     Write-Output "Path is accessible"
    #     $sqls.Add( $server)
    #   }
    # }  else {
    #   Write-Output "$server is offline"
    # }
  }
  else {
    Write-Warning  "WARN - $($server.Name) is NOT reachable"
  }

}
# export to disk  - can import in lo
$sqls | Export-Csv -Path $sqlServersCsv -UseCulture -UseQuotes -NoTypeInformation -Force
# stop logging
Stop-Transcript