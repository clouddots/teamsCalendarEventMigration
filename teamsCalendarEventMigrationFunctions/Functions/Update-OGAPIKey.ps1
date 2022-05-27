function Update-OGAPIKey {
    [CmdletBinding()]
    param ()
    $split = $GraphAPIKey.Split('.')
    $replace = $split[1].replace('-', '+').replace('_', '/')
    switch ($replace.Length % 4) {
        0 { $replace = $replace }
        1 { $replace = $replace.Substring(0, $s.Length - 1) }
        2 { $replace = $replace + "==" }
        3 { $replace = $replace + "=" }
    }
    $result = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($replace))
    [string]$expiration = $result | ConvertFrom-Json | Select-Object -ExpandProperty exp
    [datetime]$time = Get-Date
    $expirationConverted = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($expiration))
    $tokenRefreshTime = $expirationConverted - $time
    if ($tokenRefreshTime.Minutes -lt 30) {
        Get-OGAPIKey -ApplicationID $applicationID -TenantId $tenantId -AccessSecret $accessSecret
    }
}