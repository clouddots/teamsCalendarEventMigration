### TODO: RECURRENCE, Logging, Attachments, Wiki, location
# Dependency Module
Install-Module teamsCalendarEventMigrationFunctions
# New Tenant Application Variables
$applicationID = #
$tenantId = #
$accessSecret = #
# CutOver Date
[datetime]$cutOver = # ENTER CUTOVER DATE HERE #
[string]$cutOver = $cutOver.ToString("yyyy-MM-dd")
# Filter for events on type,startdate, and isOrganizer
$filterIndividualEvents = "type eq 'singleInstance' and start/dateTime ge '$($cutOver)' and isorganizer eq true"
$filterSeriesEvents = "type eq 'seriesMaster' and isorganizer eq true"
# Option Subject Append
$subjectAppend = ""
# Log Path
$logPath = "$env:USERPROFILE\Downloads\userCalendarEvents.log"
# Get API Key
Get-APIKey -ApplicationID $applicationID -TenantId $tenantId -AccessSecret $accessSecret
# Get New Tenant Users
$usersNewTenant = Get-User -All

# The property 'isOnlineMeeting' does not support filtering. This will be handled in a foreach below
foreach ($userNewTenant in $usersNewTenant) {
    # Get Individual Events for each user using filter
    $individualEvents = Get-UserEvents -UserPrincipalName $userNewTenant.userPrincipalName -Filter $filterIndividualEvents
    foreach ($individualEvent in $individualEvents) {
        # Filter for Online meeting
        if ($individualEvent.isOnlineMeeting -eq $true) {
            # Create New Event
            if ($subjectAppend) {
                try {
                    $converted = Convert-UserEvent -Event $individualEvent -CutOver $cutOver -SubjectAppend $subjectAppend
                    Write-ConvertEventLog -LogType "INFO" -User $userNewTenant.userPrincipalName -EventId $individualEvent.id -Message $converted -LogPath $logPath
                }
                catch {
                    Write-ConvertEventLog -LogType "ERROR" -User $userNewTenant.userPrincipalName -EventId $individualEvent.id -Message $_ -LogPath $logPath
                }
            }
            else {
                try {
                    $converted = Convert-UserEvent -Event $individualEvent -CutOver $cutOver
                    Write-ConvertEventLog -LogType "INFO" -User $userNewTenant.userPrincipalName -EventId $individualEvent.id -Message $converted -LogPath $logPath
                }
                catch {
                    Write-ConvertEventLog -LogType "ERROR" -User $userNewTenant.userPrincipalName -EventId $individualEvent.id -Message $_ -LogPath $logPath
                }
            }
        }
    }
    $seriesEvents = Get-UserEvents -UserPrincipalName $userNewTenant.userPrincipalName -Filter $filterSeriesEvents
    foreach ($seriesEvent in $seriesEvents) {
        # Filter for Online meeting
        if ($seriesEvent.isOnlineMeeting -eq $true) {
            if (($seriesEvent.recurrence.range.type -eq "noEnd") -or ($seriesEvent.recurrence.range.type -ge $cutOver)) {
                # Create New Event
                if ($subjectAppend) {
                    try {
                        $converted = Convert-UserEvent -Event $seriesEvent -CutOver $cutOver -SubjectAppend $subjectAppend
                        Write-ConvertEventLog -LogType "INFO" -User $userNewTenant.userPrincipalName -EventId $seriesEvent.id -Message $converted -LogPath $logPath
                    }
                    catch {
                        Write-ConvertEventLog -LogType "ERROR" -User $userNewTenant.userPrincipalName -EventId $seriesEvent.id -Message $_ -LogPath $logPath
                    }
                }
                else {
                    try {
                        $converted = Convert-UserEvent -Event $seriesEvent -CutOver $cutOver
                        Write-ConvertEventLog -LogType "INFO" -User $userNewTenant.userPrincipalName -EventId $seriesEvent.id -Message $converted -LogPath $logPath
                    }
                    catch {
                        Write-ConvertEventLog -LogType "ERROR" -User $userNewTenant.userPrincipalName -EventId $seriesEvent.id -Message $_ -LogPath $logPath
                    }
                }
            }
        }
    }
    Update-APIKey
}