### TODO: RECURRENCE, Logging, Attachments, Wiki, location
# Dependency Module
Import-Module teamsCalendarEventMigrationFunctions
# Import configuration File
$configPath = join-path -path $PSScriptRoot -childpath config.json
$config = get-content -path $configPath | convertfrom-json
# CutOver Date
[datetime]$cutOver = $config.cutOverDate
[string]$cutOver = $cutOver.ToString("yyyy-MM-dd")
# Filter for events on type,startdate, and isOrganizer
$filterIndividualEvents = "type eq 'singleInstance' and start/dateTime ge '$($cutOver)' and isorganizer eq true"
$filterSeriesEvents = "type eq 'seriesMaster' and isorganizer eq true"
# Log Path
$logPath = join-path -path $PSScriptRoot -childpath "userCalendarEvents.log"
write-information "Conversion ogs can be found in $logpath" -InformationAction Continue
# Get API Key
Get-OGAPIKey -ApplicationID $config.applicationID -TenantId $config.tenantId -AccessSecret $config.accessSecret -ErrorAction Stop
# Get New Tenant Users
$usersNewTenant = Get-OGUser -All
# The property 'isOnlineMeeting' does not support filtering. This will be handled in a foreach below
foreach ($userNewTenant in $usersNewTenant) {
    # Get Individual Events for each user using filter
    $individualEvents = Get-OGUserEvents -UserPrincipalName $userNewTenant.userPrincipalName -Filter $filterIndividualEvents
    foreach ($individualEvent in $individualEvents) {
        # Filter for Online meeting
        if ($individualEvent.isOnlineMeeting -eq $true) {
            # Create New Event
            if ($config.subjectAppend) {
                try {
                    $converted = Convert-OGUserEvent -Event $individualEvent -CutOver $cutOver -SubjectAppend $subjectAppend
                    Write-OGConvertEventLog -LogType "INFO" -User $userNewTenant.userPrincipalName -EventId $individualEvent.id -Message $converted -LogPath $logPath
                }
                catch {
                    Write-OGConvertEventLog -LogType "ERROR" -User $userNewTenant.userPrincipalName -EventId $individualEvent.id -Message $_ -LogPath $logPath
                }
            }
            else {
                try {
                    $converted = Convert-OGUserEvent -Event $individualEvent -CutOver $cutOver
                    Write-OGConvertEventLog -LogType "INFO" -User $userNewTenant.userPrincipalName -EventId $individualEvent.id -Message $converted -LogPath $logPath
                }
                catch {
                    Write-OGConvertEventLog -LogType "ERROR" -User $userNewTenant.userPrincipalName -EventId $individualEvent.id -Message $_ -LogPath $logPath
                }
            }
        }
    }
    $seriesEvents = Get-OGUserEvents -UserPrincipalName $userNewTenant.userPrincipalName -Filter $filterSeriesEvents
    foreach ($seriesEvent in $seriesEvents) {
        # Filter for Online meeting
        if ($seriesEvent.isOnlineMeeting -eq $true) {
            if (($seriesEvent.recurrence.range.type -eq "noEnd") -or ($seriesEvent.recurrence.range.type -ge $cutOver)) {
                # Create New Event
                if ($subjectAppend) {
                    try {
                        $converted = Convert-OGUserEvent -Event $seriesEvent -CutOver $cutOver -SubjectAppend $subjectAppend
                        Write-OGConvertEventLog -LogType "INFO" -User $userNewTenant.userPrincipalName -EventId $seriesEvent.id -Message $converted -LogPath $logPath
                    }
                    catch {
                        Write-OGConvertEventLog -LogType "ERROR" -User $userNewTenant.userPrincipalName -EventId $seriesEvent.id -Message $_ -LogPath $logPath
                    }
                }
                else {
                    try {
                        $converted = Convert-UserEvent -Event $seriesEvent -CutOver $cutOver
                        Write-OGConvertEventLog -LogType "INFO" -User $userNewTenant.userPrincipalName -EventId $seriesEvent.id -Message $converted -LogPath $logPath
                    }
                    catch {
                        Write-OGConvertEventLog -LogType "ERROR" -User $userNewTenant.userPrincipalName -EventId $seriesEvent.id -Message $_ -LogPath $logPath
                    }
                }
            }
        }
    }
    Update-OGAPIKey
}