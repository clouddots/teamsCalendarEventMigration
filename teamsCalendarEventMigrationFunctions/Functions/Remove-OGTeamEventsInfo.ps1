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