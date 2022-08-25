#File: Runsp.ps1
#Type: Powershell script
#Description: Script to call the stored procedure
#owner: Vichetechie

#----------------------------------------------------------------------------------------
#  Variables Assignment
#----------------------------------------------------------------------------------------


$env:VDB_INSTANCE_NAME = "your_db_instance_name"
$env:VDB_DATABASE_NAME = "your_database_name"
$fqspname = "your_stored_procedure_name"
$ConnectionTimeout = 30
$QueryTimeout = 120

#----------------------------------------------------------------------------------------
#  Creating logfile
#----------------------------------------------------------------------------------------

$dirPath = "C:\logs\"
$LogFile = $dirPath + "\" + $env:VDB_DATABASE_NAME +"_"+ (Get-Date -UFormat "%d-%m-%y") + ".log"

#----------------------------------------------------------------------------------------
#  Creating log function
#----------------------------------------------------------------------------------------

Function Write-error-log
{
    param (
        [Parameter(Mandatory=$True)]
        [array]$logoutput,
        [Parameter(Mandatory=$True)]
        [string]$Path
)
$currentDate = (Get-Date -UFormat "%d-%m-%y")
$currentTime = (Get-Date -UFormat "%T")
$logoutput = $logoutput -join (" ")
$event = "ERROR"
$LogMessage = "$Stamp $event $logoutput"
Add-Content $LogFile -Value $LogMessage
}

Function write-info-log
{
param ([string]$Logstring)
$currentDate = (Get-Date -UFormat "%d-%m-%y")
$currentTime = (Get-Date -UFormat "%T")
$stamp = "[$currentDate $currentTime]"
$event = "INFO"
$LogMessage = "$Stamp $event $LogString"
Add-Content $LogFile -Value $LogMessage 
}

#----------------------------------------------------------------------------------------
#  output the assignes varibles to the logfile
#----------------------------------------------------------------------------------------

write-info-log "***START-EXECUTION***"
write-info-log "dirpath = '$dirPath'"
write-info-log "fqspname = '$fqspname'"
write-info-log "env:VDB_INSTANCE_NAME = '$env:VDB_INSTANCE_NAME'"
write-info-log "env:VBD_DATABASE_NAME = '$env:VDB_DATABASE_NAME'"
write-info-log "ConnectionTimeout = '$ConnectionTimeout'"
write-info-log "QueryTimeout = '$QueryTimeout'"

#----------------------------------------------------------------------------------------
#  HouseKeeping: remove any existing log files older than 10 days
#----------------------------------------------------------------------------------------

write-info-log "Removing log files which are older than 10 days"
$agelimit = (Get-Date).AddDays(-10)
$logFilePattern = $env:VDB_DATABASE_NAME +"_"+ (Get-Date -UFormat "%d-%m-%y") + ".log"
write-info-log "logFilePattern = '$logFilePattern'"
Get-ChildItem -Path $dirPath -Recurse -Include $logFilePattern | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $agelimit } | Remove-Item


#----------------------------------------------------------------------------------------
#  Run the Stored procedure
#----------------------------------------------------------------------------------------

write-info-log "Running stored procedure '$fqspname' within the databse '$env:VDB_DATABASE_NAME' on the server '$env:VDB_INSTANCE_NAME'."

try {

write-info-log "open SQL Server Connection.."
$sqlserver = $env:VDB_INSTANCE_NAME
write-info-log "sqlserver = '$sqlserver'"
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.sqlserver.Smo") | Out-Null;
$conn = New-Object System.Data.SqlClient.SqlConnection
$conn.ConnectionString = "Server=$sqlserver; Database=$env:VDB_DATABASE_NAME; Integrated Security= True;"
write-info-log "conn.ConnectionString = '$conn.ConnectionString'"
$conn.Open()
$cmd1 = New-Object System.Data.SqlClient.SqlCommand($fqspname, $conn)
$cmd1.CommandTimeout=$QueryTimeout
$ds=New-Object system.Data.DataSet
$da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
[void]$da.fill($ds)
$conn.Close()
$ds.Tables
write-info-log "***Completed stored procedure '$fqspname' within database '$env:VDB_DATABASE_NAME' Successfully***"

}

Catch{
     Write-error-log -logoutput (":{0}" -f $_) -Path $LogFile
     }


#----------------------------------------------------------------------------------------
#  Exit with Success Status
#----------------------------------------------------------------------------------------

exit 0