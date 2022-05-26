## New Tenant Application Variables
$applicationID = #
$tenantId = #
$accessSecret = #
# CutOver Date
[datetime]$cutOver = # ENTER CUTOVER DATE HERE #
[string]$cutOver = $cutOver.ToString("yyyy-MM-dd")
# Filter for events on type,startdate, and isOrganizer
$filterIndividualEvents = "type eq 'singleInstance' and start/dateTime ge '$($cutOver)' and isorganizer eq true"
$filterSeriesEvents = "type eq 'seriesMaster' and isorganizer eq true"
# Get API Key
Get-OGAPIKey -ApplicationID $applicationID -TenantId $tenantId -AccessSecret $accessSecret
# Get New Tenant Users
$groupsNewTenant = Get-OGGroup -All

# The property 'isOnlineMeeting' does not support filtering. This will be handled in a foreach below
foreach ($groupNewTenant in $groupsNewTenant) {
    # Get Individual Events for each group using filter
    $individualEvents = Get-OGGroupEvents -UserPrincipalName $userNewTenant.userPrincipalName -Filter $filterIndividualEvents
    foreach ($individualEvent in $individualEvents) {
        # Filter for Online meeting
        if ($individualEvent.isOnlineMeeting -eq $true) {
            # Create New Event
            Convert-OGUserEvent -Event $individualEvent -CutOver $cutOver
        }
    }
    $seriesEvents = Get-OGUserEvents -UserPrincipalName $userNewTenant.userPrincipalName  -Filter $filterSeriesEvents
    foreach ($seriesEvent in $seriesEvents) {
        # Filter for Online meeting
        if ($seriesEvent.isOnlineMeeting -eq $true) {
            if (($seriesEvent.recurrence.range.type -eq "noEnd") -or ($seriesEvent.recurrence.range.type -ge $CutOver)) {
                # Create New Event
                Convert-OGUserEvent -Event $seriesEvent -CutOver $cutOver
            }
        }
        [datetime]$time = Get-Date
        [string]$expiration = Get-JwtPayload -jwt $GraphAPIKey | ConvertFrom-Json | Select-Object -ExpandProperty exp
        $expirationConverted = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($expiration))
        $tokenRefreshTime = $expirationConverted - $time
        if ($tokenRefreshTime.Minutes -lt 30) {
            Get-OGAPIKey -ApplicationID $applicationID -TenantId $tenantId -AccessSecret $accessSecret
        }
    }
    Update-OGAPIKey
}