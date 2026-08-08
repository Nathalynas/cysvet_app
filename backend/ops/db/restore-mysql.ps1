param(
    [Parameter(Mandatory = $true)]
    [string]$Database,

    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [string]$Password,

    [Parameter(Mandatory = $true)]
    [string]$BackupFile,

    [string]$DbHost = "127.0.0.1",
    [int]$Port = 3306,
    [string]$ContainerName
)

$resolvedBackupFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($BackupFile)

if (-not (Test-Path $resolvedBackupFile)) {
    throw "Arquivo de backup nao encontrado: $resolvedBackupFile"
}

if ($ContainerName) {
    $containerRestoreFile = "/tmp/restore-$Database.sql"
    $restoreCommand = "exec mysql -h '$DbHost' -P '$Port' -u '$Username' --password='$Password' '$Database' < '$containerRestoreFile'"

    try {
        & docker cp $resolvedBackupFile "${ContainerName}:$containerRestoreFile" | Out-Null
        & docker exec $ContainerName sh -lc $restoreCommand
    } finally {
        & docker exec $ContainerName rm -f $containerRestoreFile | Out-Null
    }
} else {
    $mysql = Get-Command mysql -ErrorAction Stop
    $restoreArgs = @(
        "-h", $DbHost,
        "-P", "$Port",
        "-u", $Username,
        "--password=$Password",
        $Database
    )

    Get-Content -Path $resolvedBackupFile | & $mysql.Source @restoreArgs
}

Write-Output "Restore concluido para $Database"
