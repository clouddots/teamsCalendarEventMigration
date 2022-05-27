function Get-OGUserEvents {
    param (
        [Parameter(Mandatory = $True)]$UserPrincipalName,
        [Parameter(Mandatory = $False)]$Filter
    )
    if ($filter) {

        $URI = "https://graph.microsoft.com/$GraphVersion/users/$userprincipalname/events?`$filter=$filter"
        Get-OGNextPage -URI $URI
    }
    else {
        $URI = "https://graph.microsoft.com/$GraphVersion/users/$userprincipalname/events"
        Get-OGNextPage -URI $URI
    }
}