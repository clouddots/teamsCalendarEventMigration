function Get-User {
    [CmdletBinding(DefaultParameterSetName = 'UPN')]
    param (
        [Parameter(Mandatory = $False,
            ParameterSetName = 'UPN')]$UserPrincipalName,
        [Parameter(Mandatory = $False,
            ParameterSetName = 'Search')]$SearchDisplayName,
        [Parameter(Mandatory = $False,
            ParameterSetName = 'All')][Switch]$All
    )
    if ($UserPrincipalName) {
        $account_params = @{
            Headers     = @{Authorization = "Bearer $($GraphAPIKey)" }
            URI         = "https://graph.microsoft.com/$GraphVersion/users/$userprincipalname"
            Method      = 'GET'
            ContentType = 'application/json'
        }
        Invoke-RestMethod @Account_params
    }
    if ($SearchDisplayName) {
        $URI = "https://graph.microsoft.com/$GraphVersion/users?`$search=`"displayName:$SearchDisplayName`""
        Get-NextPage -uri $URI -SearchDisplayName
    }
    if ($All) {
        $URI = "https://graph.microsoft.com/$GraphVersion/users"
        Get-NextPage -Uri $URI
    }
}