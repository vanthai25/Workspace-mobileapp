param(
    [Parameter(Mandatory = $true)][string]$TemplatePath,
    [Parameter(Mandatory = $true)][string]$OutputDirectory
)
$ErrorActionPreference = 'Stop'
$settings = [System.Xml.XmlReaderSettings]::new()
$settings.DtdProcessing = [System.Xml.DtdProcessing]::Prohibit
$settings.XmlResolver = $null
$reader = [System.Xml.XmlReader]::Create($TemplatePath, $settings)
$document = [System.Xml.XmlDocument]::new()
$document.XmlResolver = $null
try { $document.Load($reader) } finally { $reader.Dispose() }
if ($document.SelectSingleNode('/PrintSuport/prtdmmauin/idmauin').InnerText -ne '376') {
    throw 'This extractor is only for the reviewed template 376.'
}
$cells = @($document.SelectNodes('/PrintSuport/prtthietlapcell') | Where-Object { $_.visible -eq 'true' })
$checks = @($cells | Where-Object { $_.fieldname -like 'NDG5!*' })
if ($checks.Count -ne 32) { throw "Expected 32 checkboxes; got $($checks.Count). Review the template." }

# Three labels are in a different logical row from their checkbox.
# These cell references were verified against the XML coordinates and template.
$labelCells = @{
    btgmotuyen1 = @(28, 0)
    btgmotuyen2 = @(30, 2)
    btgbieumovay5 = @(34, 0)
}
$fields = foreach ($cell in ($checks | Sort-Object { [double]$_.top }, { [double]$_.left })) {
    if ([string]$cell.compute -ne "IIF('{0}' = 'True', 'X', '')") {
        throw 'Unexpected checkbox expression. Review its meaning before importing.'
    }
    $key = ([string]$cell.fieldname).Substring(5)
    $labelRow = [int]$cell.row
    $labelCol = [int]$cell.col + 1
    if ($labelCells.ContainsKey($key)) {
        $labelRow = $labelCells[$key][0]
        $labelCol = $labelCells[$key][1]
    }
    $labels = @($cells | Where-Object {
        $_.block -eq $cell.block -and $_.vungin -eq $cell.vungin -and
        [int]$_.row -eq $labelRow -and [int]$_.col -eq $labelCol -and
        -not $_.fieldname -and $_.defaulttext
    })
    if ($labels.Count -ne 1) { throw "Cannot uniquely match label for $key." }
    $label = $labels[0]
    $row = [int]$cell.row
    $group = if ($row -eq 13) { 'assessment' }
        elseif ($row -eq 16) { 'negative' }
        elseif ($row -le 19) { 'non_neoplastic' }
        elseif ($row -le 23) { 'infection' }
        elseif ($row -eq 25) { 'endometrial' }
        elseif ($row -eq 26) { 'epithelial' }
        elseif ($row -le 36 -and [double]$cell.left -lt 90) { 'squamous' }
        elseif ($row -le 36) { 'glandular' }
        else { 'other' }
    [pscustomobject][ordered]@{
        name = $key
        label = ([string]$label.defaulttext -replace '\s+', ' ').Trim()
        group = $group
        row = $row
        column = [int]$cell.col
        labelRow = $labelRow
        labelColumn = $labelCol
        x = [double]$cell.left
        y = [double]$cell.top
        bold = ([string]$label.font -match 'Bold')
        italic = ([string]$label.font -match 'Italic')
    }
}
$manifest = [ordered]@{
    templateId = '376'
    formId = 12 # Supplied separately from the API; not encoded in this .prt.
    sourceSha256 = (Get-FileHash -LiteralPath $TemplatePath -Algorithm SHA256).Hash
    title = [string]($cells | Where-Object { $_.vungin -eq '1' -and $_.row -eq '4' -and $_.col -eq '0' }).defaulttext
    resultTitle = [string]($cells | Where-Object { $_.vungin -eq '1' -and $_.row -eq '14' -and $_.col -eq '0' }).defaulttext
    fields = @($fields)
}
$utf8 = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText((Join-Path $OutputDirectory 'gpb_376_template.json'),
    ($manifest | ConvertTo-Json -Depth 6), $utf8)
$ordinal = 0
$csv = $fields | ForEach-Object {
    $ordinal++
    [pscustomobject][ordered]@{
        name = $_.name; nhan_hien_thi = $_.label; nhom = $_.group; thu_tu = $ordinal
    }
} | ConvertTo-Csv -NoTypeInformation
[System.IO.File]::WriteAllLines((Join-Path $OutputDirectory 'gpb_376_form_12_labels.csv'), $csv, $utf8)
Write-Output "Extracted $($fields.Count) labels. Embedded SQL and compute expressions were not executed."
