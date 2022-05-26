$GraphAPIKey = "v1.0"

$NoExport = ''
$ModuleFunctions = @(Get-ChildItem -Path $PSScriptRoot\Functions\*.ps1 -ErrorAction SilentlyContinue)
$ToExport = $ModuleFunctions | Where-Object { $_.BaseName -notin $NoExport } | Select-Object -ExpandProperty BaseName
# Dot-source the files.
foreach ($import in $ModuleFunctions) {
    try {
        Write-Verbose "Importing $($import.FullName)"
        . $import.FullName
    }
    catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}
Export-ModuleMember -Function $ToExport -Variable GraphAPIKey