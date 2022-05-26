$Script:GraphVersion = "v1.0"
function Get-OGNextPage {
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
        Get-OGNextPage -Uri $results."@odata.nextlink"
    }
    elseif (!$results."@odata.nextlink") {
        $Result.Value
    }
}
function Get-OGAPIKey {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]$ApplicationID,
        [Parameter(Mandatory)]$TenantId,
        [Parameter(Mandatory)]$AccessSecret
    )
    $Body = @{    
        Grant_Type    = "client_credentials"
        Scope         = "https://graph.microsoft.com/.default"
        client_Id     = $ApplicationID
        Client_Secret = $AccessSecret
    } 
    $ConnectGraph = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Method POST -Body $Body
    $Script:GraphAPIKey = $ConnectGraph.access_token
}
function Update-OGAPIKey {
    [CmdletBinding()]
    param ()
    [datetime]$time = Get-Date
    [string]$expiration = Get-JwtPayload -jwt $GraphAPIKey | ConvertFrom-Json | Select-Object -ExpandProperty exp
    $expirationConverted = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($expiration))
    $tokenRefreshTime = $expirationConverted - $time
    if ($tokenRefreshTime.Minutes -lt 30) {
        Get-OGAPIKey -ApplicationID $applicationID -TenantId $tenantId -AccessSecret $accessSecret
    }
}
function Get-OGUser {
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
        Get-OGNextPage -uri $URI -SearchDisplayName
    }
    if ($All) {
        $URI = "https://graph.microsoft.com/$GraphVersion/users"
        Get-OGNextPage -Uri $URI
    }   
}
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
function Remove-OGTeamsEventInfo {
    param (
        [Parameter(Mandatory = $True)]$html
    )
    $stringbyline = $html -split "`r`n" 
    $Underscores = $stringbyline | Select-String "________________________________________________________________________________"
    if ($Underscores) {
        $Startline = $Underscores[0].LineNumber - 2
        $Endline = $Underscores[1].LineNumber
        $expectedContent = $stringbyline[$Startline..$Endline] | Select-String -simplematch "teams.microsoft.com"
        if ($expectedContent) {
            $TotalLines = $stringbyline.count - 1
            $stringbyline[0..$Startline], $stringbyline[$Endline..$TotalLines] | Out-String
        }
    }
}
function Convert-OGUserEvent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][PSObject]$Event,
        [Parameter(Mandatory = $false)][datetime]$CutOver,
        [Parameter(Mandatory)][string]$SubjectAppend

    )
    $Body = @{}
    if ($Event.subject) {
        if ($SubjectAppend) {
            $Subject = $SubjectAppend + " - " + $Event.subject
        }
        else {
            $Subject = $Event.subject
        }
        $body.subject = $Subject
    }
    if ($Event.body.content) {
        $updateContent = Remove-OGTeamsEventInfo -html $Event.body.content
        $bodyContent = [PSCustomObject]@{
            contentType = "HTML"
            content     = $updateContent
        }
        $body.body = $bodycontent
    }
    if ($Event.start) {
        $body.start = $Event.start
    }
    if ($Event.end) {
        $body.end = $Event.end
        }
    if ($event.recurrence) {
        $recurrence = $event.recurrence
        if ($CutOver) {
            [string]$CutOver = $CutOver.ToString("yyyy-MM-dd")
            $recurrence.range.startDate = $CutOver
        }
        $body.recurrence = $event.recurrence
    }
    if ($event.location.displayName) {
        $location = [PSCustomObject]@{
            displayName = $event.location.displayName
        }
        $body.location.displayName = $location
    }
    if ($event.attendees) {
        $array = @(
            foreach ($attendeeItem in $event.attendees) {
                $attendees = @{}
                $emailAddress = [PSCustomObject]@{
                    address = $attendeeItem.emailAddress.address
                    name    = $attendeeItem.emailAddress.name
                }
                $attendees.emailaddress = $emailAddress
                $type = $attendeeItem.type
                $attendees.type = $type
                $attendees
            })
        $body.attendees = $array
    }
    if ($event.allowNewTimeProposals) {
        $allowNewTimeProposals = $event.allowNewTimeProposals
        $body.allowNewTimeProposals = $allowNewTimeProposals
    }
    $body.isOnlineMeeting = "true"
    $body.onlineMeetingProvider = "teamsForBusiness"

    $account_params = @{
        Headers     = @{Authorization = "Bearer $($GraphAPIKey)" }
        Uri         = "https://graph.microsoft.com/$GraphVersion/users/$($Event.organizer.emailaddress.address)/events"
        body        = $Body | ConvertTo-Json -Depth 10
        Method      = 'POST'
        ContentType = 'application/json'
    }
    Invoke-RestMethod @Account_params
}
Function Write-ConvertEventLog {
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
function ConvertFrom-Base64UrlString {
    <#
    .SYNOPSIS
    Base64url decoder.
     
    .DESCRIPTION
    Decodes base64url-encoded string to the original string or byte array.
     
    .PARAMETER Base64UrlString
    Specifies the encoded input. Mandatory string.
     
    .PARAMETER AsByteArray
    Optional switch. If specified, outputs byte array instead of string.
     
    .INPUTS
    You can pipe the string input to ConvertFrom-Base64UrlString.
     
    .OUTPUTS
    ConvertFrom-Base64UrlString returns decoded string by default, or the bytes if -AsByteArray is used.
     
    .EXAMPLE
     
    PS Variable:> 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9' | ConvertFrom-Base64UrlString
    {"alg":"RS256","typ":"JWT"}
     
    .LINK
    https://github.com/SP3269/posh-jwt
    .LINK
    https://jwt.io/
     
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)][string]$Base64UrlString,
        [Parameter(Mandatory = $false)][switch]$AsByteArray
    )
    $s = $Base64UrlString.replace('-', '+').replace('_', '/')
    switch ($s.Length % 4) {
        0 { $s = $s }
        1 { $s = $s.Substring(0, $s.Length - 1) }
        2 { $s = $s + "==" }
        3 { $s = $s + "=" }
    }
    if ($AsByteArray) {
        return [Convert]::FromBase64String($s) # Returning byte array - convert to string by using [System.Text.Encoding]::{{UTF8|Unicode|ASCII}}.GetString($s)
    }
    else {
        return [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($s))
    }
}
function Get-JwtPayload {
    <#
        .SYNOPSIS
        Gets JSON payload from a JWT (JSON Web Token).
         
        .DESCRIPTION
        Decodes and extracts JSON payload from JWT. Ignores headers and signature.
         
        .PARAMETER jwt
        Specifies the JWT. Mandatory string.
         
        .INPUTS
        You can pipe JWT as a string object to Get-JwtPayload.
         
        .OUTPUTS
        String. Get-JwtPayload returns decoded payload part of the JWT.
         
        .EXAMPLE
         
        PS Variable:> $jwt | Get-JwtPayload -Verbose
        VERBOSE: Processing JWT: eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbjEiOiJ2YWx1ZTEiLCJ0b2tlbjIiOiJ2YWx1ZTIifQ.Kd12ryF7Uuk9Y1UWsqdSk6cXNoYZBf9GBoqcEz7R5e4ve1Kyo0WmSr-q4XEjabcbaG0hHJyNGhLDMq6BaIm-hu8ehKgDkvLXPCh15j9AzabQB4vuvSXSWV3MQO7v4Ysm7_sGJQjrmpiwRoufFePcurc94anLNk0GNkTWwG59wY4rHaaHnMXx192KnJojwMR8mK-0_Q6TJ3bK8lTrQqqavnCW9vrKoWoXkqZD_4Qhv2T6vZF7sPkUrgsytgY21xABQuyFrrNLOI1g-EdBa7n1vIyeopM4n6_Uk-ttZp-U9wpi1cgg2pRIWYV5ZT0AwZwy0QyPPx8zjh7EVRpgAKXDAg
        {"token1":"value1","token2":"value2"}
         
        .LINK
        https://github.com/SP3269/posh-jwt
        .LINK
        https://jwt.io/
         
        #>
            
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)][string]$jwt
    )
        
    Write-Verbose "Processing JWT: $jwt"
    $parts = $jwt.Split('.')
    $payload = ConvertFrom-Base64UrlString $parts[1]
    return $payload
}