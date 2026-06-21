# Exchange DNS Record Validator

PowerShell tools for validating Exchange Online DNS records, producing a remediation plan, and optionally adding missing records to an authorised Windows DNS zone.

## Validate

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Exchange_DNS_Record_Validator.ps1 -Domain example.com
```

## Repair or create a plan

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Exchange_DNS_Record_Repair_Toolkit.ps1 -Domain example.com -MxTarget example-com.mail.protection.outlook.com -AutodiscoverTarget autodiscover.outlook.com
```

Apply missing records to Windows DNS only after review:

```powershell
.\Exchange_DNS_Record_Repair_Toolkit.ps1 -Domain example.com -DnsServer DNS01 -MxTarget example-com.mail.protection.outlook.com -SpfValue 'v=spf1 include:spf.protection.outlook.com -all' -ApplyWindowsDns -DryRun
```

The workflow creates a CSV remediation plan by default. With `-ApplyWindowsDns`, it validates the zone and adds only the explicitly supplied records. It captures public DNS state before and after, supports `-DryRun`, confirmation, logs and clear exit codes. It does not delete or replace existing records automatically.

## Author

Dewald Pretorius — L2 IT Support Engineer
