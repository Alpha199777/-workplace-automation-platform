# 📖 Installation Guide — Workplace Automation Platform

## Prerequisites
- Microsoft 365 tenant (SharePoint Online + Power Automate + Forms)
- PowerShell 7+ with PnP.PowerShell module
- OpenAI API key
- Power BI Desktop

## Step 1 — Install PnP.PowerShell
```powershell
Install-Module PnP.PowerShell -Force
```

## Step 2 — Set OpenAI API Key
```powershell
setx OPENAI_API_KEY "sk-your-key-here" /M
```

## Step 3 — Deploy Script
```powershell
New-Item -ItemType Directory -Force -Path "C:\Scripts\Logs"
Copy-Item "scripts/SharePoint_AI_Fixed.ps1" -Destination "C:\Scripts\"
```

## Step 4 — Create Scheduled Task
```powershell
Register-ScheduledTask `
    -TaskName "WorkplaceAI_SharePoint_Enrichment" `
    -Action (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\Scripts\SharePoint_AI_Fixed.ps1") `
    -Trigger (New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Hours 4) -Once -At (Get-Date)) `
    -RunLevel Highest -Force
```

## Step 5 — Power BI
Open `power-bi/Workplace_Dashboard.pbix` → Update SharePoint URL → Refresh.
