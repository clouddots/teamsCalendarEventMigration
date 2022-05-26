function Get-NextPage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)][string]$URI,
        [Switch]$SearchDisplayName
    )
    $account_params = @{
        Headers     = @{Authorization = "Bearer $($GraphAPIKey)" }
        URI         = $URI
        Method      = 'GET'
        ContentType = 'application/json'
    }
    if ($SearchDisplayName) {
        $account_params.headers.add("ConsistencyLevel", "eventual")
    }
    $Result = Invoke-RestMethod @Account_params
    if ($results."@odata.nextlink") {
        Get-NextPage -Uri $results."@odata.nextlink"
    }
    elseif (!$results."@odata.nextlink") {
        $Result.Value
    }
}