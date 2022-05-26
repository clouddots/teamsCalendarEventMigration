function Get-UserEvents {
    param (
        [Parameter(Mandatory = $True)]$UserPrincipalName,
        [Parameter(Mandatory = $False)]$Filter
    )
    if ($filter) {

        $URI = "https://graph.microsoft.com/$GraphVersion/users/$userprincipalname/events?`$filter=$filter"
        Get-NextPage -URI $URI
    }
    else {
        $URI = "https://graph.microsoft.com/$GraphVersion/users/$userprincipalname/events"
        Get-NextPage -URI $URI
    }
}