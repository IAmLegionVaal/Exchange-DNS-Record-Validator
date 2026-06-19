# Exchange DNS Record Validator

A read-only PowerShell toolkit for validating Exchange Online DNS records.

## Features

- MX, SPF, DMARC, and autodiscover checks
- Optional DKIM selector checks
- Expected-value comparison support
- CSV, JSON, and HTML reports

## Run

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Exchange_DNS_Record_Validator.ps1 -Domain example.com
```

## Safety

Read-only DNS queries only. No DNS or tenant settings are changed.
