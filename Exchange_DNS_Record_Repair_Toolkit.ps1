[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
param(
 [Parameter(Mandatory)][string]$Domain,
 [string]$DnsServer=$env:COMPUTERNAME,
 [string]$MxTarget,
 [int]$MxPreference=0,
 [string]$AutodiscoverTarget,
 [string]$SpfValue,
 [string]$DmarcValue,
 [switch]$ApplyWindowsDns,
 [switch]$DryRun,
 [switch]$Yes,
 [string]$OutputPath=(Join-Path $env:ProgramData 'ExchangeDnsRepair')
)
$ErrorActionPreference='Stop';$script:Failures=0;$script:Actions=0
$run=Join-Path $OutputPath (Get-Date -Format yyyyMMdd_HHmmss);New-Item -ItemType Directory $run -Force|Out-Null
$log=Join-Path $run 'repair.log';$before=Join-Path $run 'before.json';$after=Join-Path $run 'after.json';$plan=Join-Path $run 'remediation-plan.csv'
function Log($m){"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m"|Tee-Object -FilePath $log -Append}
function State{[pscustomobject]@{Collected=Get-Date;MX=Resolve-DnsName $Domain -Type MX -ErrorAction SilentlyContinue;SPF=Resolve-DnsName $Domain -Type TXT -ErrorAction SilentlyContinue|Where-Object Strings -match 'v=spf1';DMARC=Resolve-DnsName "_dmarc.$Domain" -Type TXT -ErrorAction SilentlyContinue;Autodiscover=Resolve-DnsName "autodiscover.$Domain" -Type CNAME -ErrorAction SilentlyContinue}}
function Act($d,[scriptblock]$a){$script:Actions++;Log $d;if($DryRun){Log "DRY-RUN: $d";return};try{&$a;Log "SUCCESS: $d"}catch{$script:Failures++;Log "FAILED: $d - $($_.Exception.Message)"}}
$zone=$Domain.TrimEnd('.');State|ConvertTo-Json -Depth 6|Set-Content $before -Encoding UTF8
$rows=@();if($MxTarget){$rows+=[pscustomobject]@{Type='MX';Name='@';Value=$MxTarget;Preference=$MxPreference}};if($AutodiscoverTarget){$rows+=[pscustomobject]@{Type='CNAME';Name='autodiscover';Value=$AutodiscoverTarget;Preference=''}};if($SpfValue){$rows+=[pscustomobject]@{Type='TXT';Name='@';Value=$SpfValue;Preference=''}};if($DmarcValue){$rows+=[pscustomobject]@{Type='TXT';Name='_dmarc';Value=$DmarcValue;Preference=''}}
if(-not $rows){Write-Error 'Supply at least one expected DNS record value.';exit 2};$rows|Export-Csv $plan -NoTypeInformation
if($ApplyWindowsDns){Import-Module DnsServer -ErrorAction Stop;Get-DnsServerZone -ComputerName $DnsServer -Name $zone -ErrorAction Stop|Out-Null;if(-not $Yes -and -not $DryRun){if((Read-Host "Add missing Exchange DNS records to zone '$zone' on '$DnsServer'? Type YES") -ne 'YES'){Log 'Cancelled.';exit 10}};foreach($r in $rows){switch($r.Type){'MX'{Act "Adding MX record $($r.Value)" {Add-DnsServerResourceRecordMX -ComputerName $DnsServer -ZoneName $zone -Name '@' -MailExchange $r.Value -Preference $r.Preference -TimeToLive ([timespan]::FromHours(1))}}'CNAME'{Act "Adding CNAME $($r.Name) -> $($r.Value)" {Add-DnsServerResourceRecordCName -ComputerName $DnsServer -ZoneName $zone -Name $r.Name -HostNameAlias $r.Value -TimeToLive ([timespan]::FromHours(1))}}'TXT'{Act "Adding TXT record $($r.Name)" {Add-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $zone -Txt -Name $r.Name -DescriptiveText $r.Value -TimeToLive ([timespan]::FromHours(1))}}}}}
else{Log "Remediation plan created at $plan. No DNS changes requested."}
Start-Sleep 2;State|ConvertTo-Json -Depth 6|Set-Content $after -Encoding UTF8
if($script:Failures){exit 20};Log "Workflow completed. Actions: $script:Actions";exit 0
