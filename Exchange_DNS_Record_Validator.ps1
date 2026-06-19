#requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory)][string]$Domain,[string[]]$DkimSelectors=@('selector1','selector2'),[string]$OutputPath)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
if([string]::IsNullOrWhiteSpace($OutputPath)){$OutputPath=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Exchange_DNS_Reports'}
New-Item -ItemType Directory -Path $OutputPath -Force|Out-Null
$queries=@([PSCustomObject]@{Name=$Domain;Type='MX'},[PSCustomObject]@{Name=$Domain;Type='TXT'},[PSCustomObject]@{Name="_dmarc.$Domain";Type='TXT'},[PSCustomObject]@{Name="autodiscover.$Domain";Type='CNAME'})
foreach($selector in $DkimSelectors){$queries+=[PSCustomObject]@{Name="$selector._domainkey.$Domain";Type='CNAME'}}
$rows=@()
foreach($q in $queries){try{$answers=Resolve-DnsName -Name $q.Name -Type $q.Type -ErrorAction Stop;$value=(($answers|ForEach-Object{$_.NameExchange,$_.NameHost,$_.Strings,$_.IPAddress}|Where-Object{$_}) -join '; ');$rows+=[PSCustomObject]@{Name=$q.Name;Type=$q.Type;Success=$true;Value=$value;Error=$null}}catch{$rows+=[PSCustomObject]@{Name=$q.Name;Type=$q.Type;Success=$false;Value=$null;Error=$_.Exception.Message}}}
$rows|Export-Csv (Join-Path $OutputPath "exchange_dns_$stamp.csv") -NoTypeInformation -Encoding UTF8
$rows|ConvertTo-Json -Depth 6|Set-Content (Join-Path $OutputPath "exchange_dns_$stamp.json") -Encoding UTF8
$html="<h1>Exchange DNS Validation - $Domain</h1><p>Generated $(Get-Date)</p>$($rows|ConvertTo-Html -Fragment)"
$html|ConvertTo-Html -Title 'Exchange DNS Validation'|Set-Content (Join-Path $OutputPath "exchange_dns_$stamp.html") -Encoding UTF8
$rows|Format-Table -AutoSize
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
