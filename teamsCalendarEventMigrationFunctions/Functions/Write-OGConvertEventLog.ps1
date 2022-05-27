Function Write-OGConvertEventLog {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False)]
        [ValidateSet("INFO", "WARN", "ERROR", "FATAL", "DEBUG")]
        [String]
        $LogType,

        [Parameter(Mandatory = $True)]
        [string]
        $User,

        [Parameter(Mandatory = $True)]
        [string]
        $EventId,

        [Parameter(Mandatory = $True)]
        [string]
        $Message,

        [Parameter(Mandatory = $False)]
        [string]
        $LogPath
    )

    $logObject = [PSCustomObject]@{
        Time    = $((Get-Date).toString("yyyy/MM/dd HH:mm:ss"))
        LogType = $LogType
        UPN     = $User
        EventId = $EventId
        Message = $Message
    }
    Export-Csv -Path $LogPath -InputObject $logObject -NoTypeInformation -Append
}