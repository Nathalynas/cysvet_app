param(
    [Parameter(Mandatory = $true)]
    [string]$Database,

    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [string]$Password,

    [string]$DbHost = "127.0.0.1",
    [int]$Port = 3306,
    [string]$BackupDir = ".\\backups",
    [int]$RetentionDays = 14,
    [string]$ContainerName
)

$resolvedBackupDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($BackupDir)
New-Item -ItemType Directory -Path $resolvedBackupDir -Force | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupFile = Join-Path $resolvedBackupDir "$Database-$timestamp.sql"

if ($ContainerName) {
    $containerBackupFile = "/tmp/$Database-$timestamp.sql"
    $dumpCommand = "exec mysqldump -h '$DbHost' -P '$Port' -u '$Username' --password='$Password' --single-transaction --quick --routines --triggers '$Database' > '$containerBackupFile'"

    try {
        & docker exec $ContainerName sh -lc $dumpCommand
        & docker cp "${ContainerName}:$containerBackupFile" $backupFile | Out-Null
    } finally {
        & docker exec $ContainerName rm -f $containerBackupFile | Out-Null
    }
} else {
    $mysqldump = Get-Command mysqldump -ErrorAction Stop
    $dumpArgs = @(
        "-h", $DbHost,
        "-P", "$Port",
        "-u", $Username,
        "--password=$Password",
        "--single-transaction",
        "--quick",
        "--routines",
        "--triggers",
        $Database
    )

    & $mysqldump.Source @dumpArgs | Set-Content -Path $backupFile -Encoding utf8
}

if (-not (Test-Path $backupFile)) {
    throw "Backup nao foi gerado em $backupFile"
}

$cutoff = (Get-Date).AddDays(-1 * $RetentionDays)
Get-ChildItem -Path $resolvedBackupDir -Filter "$Database-*.sql" -File |
    Where-Object { $_.LastWriteTime -lt $cutoff } |
    Remove-Item -Force

Write-Output $backupFile
