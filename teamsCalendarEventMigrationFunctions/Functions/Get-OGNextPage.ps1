Function Get-OGNextPage {
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
    switch ($PSBoundParameters.Keys -contains 'SearchDisplayName') {
        $true {
            $account_params.headers.add('ConsistencyLevel', 'eventual')
        }
    }
    $Result = Invoke-RestMethod @Account_params
    $Result.value
    if ($result.'@odata.nextlink') {
        Get-OGNextPage -Uri $result.'@odata.nextlink'
    }
}