function Get-OGUserEventInstances {
    param (
        [Parameter(Mandatory = $True)]$UserPrincipalName,
        [Parameter(Mandatory = $True)]$EventId,
        [Parameter(Mandatory = $True)][datetime]$StartDate,
        [Parameter(Mandatory = $True)][datetime]$EndDate

    )
    $StartDate = $StartDate.toString('s')
    $EndDate = $EndDate.toString('s')
    $URI = "https://graph.microsoft.com/$GraphVersion/users/$userprincipalname/events?startDateTime=$startdate&endDateTime=$EndDate"
    Get-OGNextPage -URI $URI
}