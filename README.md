
End-to-end workplace automation platform using PowerShell, Power Automate, SharePoint Online &amp; OpenAI GPT-4
# 🏢 Workplace Automation Platform

![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Power Automate](https://img.shields.io/badge/Power%20Automate-0066FF?style=for-the-badge&logo=microsoft&logoColor=white)
![SharePoint](https://img.shields.io/badge/SharePoint-0078D4?style=for-the-badge&logo=microsoft-sharepoint&logoColor=white)
![OpenAI](https://img.shields.io/badge/OpenAI%20GPT--4-412991?style=for-the-badge&logo=openai&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Microsoft 365](https://img.shields.io/badge/Microsoft%20365-D83B01?style=for-the-badge&logo=microsoft&logoColor=white)

> **End-to-end workplace automation platform** — From form submission to AI-enriched SharePoint registry with Power BI monitoring. Built as a technical showcase for IT Workplace Engineer positions.

---

## 🎯 What This Project Does

A user submits a project request via **Microsoft Forms** → **Power Automate** triggers an approval workflow → Once approved, the project is created in **SharePoint** → A **PowerShell script** automatically enriches each project with **OpenAI GPT-4** (summary, tags, recommendations) → A **Power BI dashboard** monitors everything in real time.

**Zero manual intervention after form submission.**

---

## 🏗️ Architecture

```
Microsoft Forms (PROJET-LION-2026 v2)
         │
         ▼
Power Automate Flow
  ├── Trigger: New form response
  ├── Action: Get response details
  ├── Action: Start approval (email notification)
  └── Condition: Outcome == "Approve"
         │
    ✅ YES branch
         │
         ├── Create SharePoint item (AI_Status: Pending)
         └── Send confirmation email
                  │
                  ▼
         Windows Scheduled Task
         (every 4 hours)
                  │
                  ▼
    SharePoint_AI_Fixed.ps1
    ├── Connect-PnPOnline (Device Login)
    ├── Get items where AI_Status != Done
    ├── Call OpenAI GPT-4.1-mini API
    │   └── Returns: summary, tags, recommendations
    └── Update SharePoint columns:
        ├── AI_Summary
        ├── AI_Tags
        ├── AI_Recommendations
        ├── AI_Status → "Done"
        ├── AI_LastProcessed
        └── AI_Model
                  │
                  ▼
         Power BI Dashboard
         └── Real-time monitoring
             ├── Projects by Status (Done/Pending/Error)
             ├── Projects by Impact
             ├── AI-generated Tags cloud
             └── KPI cards
```

---

## 🛠️ Tech Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Form** | Microsoft Forms | Project request intake |
| **Orchestration** | Power Automate | Approval workflow + SharePoint creation |
| **Backend** | PowerShell 7 + PnP.PowerShell | SharePoint automation |
| **AI** | OpenAI GPT-4.1-mini | Project enrichment (summary, tags, reco) |
| **Storage** | SharePoint Online List | Project registry with AI columns |
| **Scheduling** | Windows Task Scheduler | Automated script execution every 4h |
| **Monitoring** | Power BI Desktop | Real-time dashboard |

---

## 📁 Repository Structure

```
workplace-automation-platform/
│
├── 📜 README.md
│
├── 🔧 scripts/
│   └── SharePoint_AI_Fixed.ps1       # Main PowerShell + OpenAI script
│
├── ⚡ power-automate/
│   └── flow-architecture.md          # Power Automate flow documentation
│
├── 📊 power-bi/
│   └── Workplace_Dashboard.pbix      # Power BI dashboard file
│
├── 📸 screenshots/
│   ├── dashboard-overview.png        # Power BI dashboard
│   ├── sharepoint-registry.png       # SharePoint list with AI columns
│   ├── power-automate-flow.png       # Flow architecture
│   └── approval-email.png            # Approval email screenshot
│
└── 📖 docs/
    └── INSTALLATION.md               # Step-by-step setup guide
```

---

## ⚡ Power Automate Flow

```
Trigger → Get Details → Approval → Condition
                                      │
                              ┌───────┴───────┐
                           ✅ Approve      ❌ Reject
                              │               │
                    Create SharePoint      End flow
                    item (Pending)
                              │
                    Send confirmation
                    email to submitter
```

**Condition expression (fx):**
```
outputs('Démarrer_et_attendre_une_approbation')?['body/outcome']
```
> ⚠️ Use the `fx` expression editor — not the dynamic content picker — to correctly reference the `outcome` field.

---

## 🤖 AI Enrichment Script

The PowerShell script `SharePoint_AI_Fixed.ps1` processes all items with `AI_Status != Done`:

```powershell
# Key features:
# ✅ Connects to SharePoint via PnP.PowerShell (Device Login)
# ✅ Calls OpenAI /v1/chat/completions with json_object response format
# ✅ Retry logic for 429 (Too Many Requests) with exponential backoff
# ✅ Updates 6 SharePoint columns per item
# ✅ Error handling with AI_Status = "Error" fallback
```

**SharePoint columns created:**

| Column | Type | Description |
|--------|------|-------------|
| `AI_Summary` | Text | GPT-generated project summary |
| `AI_Tags` | Text | Comma-separated relevant tags |
| `AI_Recommendations` | Text | 3 actionable recommendations |
| `AI_Status` | Choice | Pending / Done / Error |
| `AI_LastProcessed` | DateTime | UTC timestamp of last AI run |
| `AI_Model` | Text | Model used (gpt-4.1-mini) |

---

## 🚀 Installation Guide

### Prerequisites

- Microsoft 365 tenant (SharePoint Online + Power Automate + Forms)
- PowerShell 7+ with PnP.PowerShell module
- OpenAI API key
- Power BI Desktop

### Step 1 — SharePoint Setup

Create a SharePoint list named **"Registre des Projets"** with these columns:
- `Title` (Text)
- `Description` (Text)
- `Impact` (Choice: Innovation / Gain de productivité / Réduction des coûts)
- `AI_Summary`, `AI_Tags`, `AI_Recommendations` (Text)
- `AI_Status` (Choice: Pending / Done / Error)
- `AI_LastProcessed` (DateTime)
- `AI_Model` (Text)

### Step 2 — Azure App Registration

Register an app in Azure AD with SharePoint `Sites.ReadWrite.All` permissions for PnP Device Login.

### Step 3 — Environment Variables

```powershell
# Set OpenAI API key as system variable (required for scheduled task)
setx OPENAI_API_KEY "sk-your-key-here" /M
```

### Step 4 — Deploy the Script

```powershell
# Create directory
New-Item -ItemType Directory -Force -Path "C:\Scripts\Logs"

# Copy script
Copy-Item "scripts/SharePoint_AI_Fixed.ps1" -Destination "C:\Scripts\"
```

### Step 5 — Create Scheduled Task

```powershell
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NonInteractive -WindowStyle Hidden -File `"C:\Scripts\SharePoint_AI_Fixed.ps1`""

$trigger = New-ScheduledTaskTrigger `
    -RepetitionInterval (New-TimeSpan -Hours 4) `
    -Once -At (Get-Date)

Register-ScheduledTask `
    -TaskName "WorkplaceAI_SharePoint_Enrichment" `
    -Action $action -Trigger $trigger `
    -RunLevel Highest -Force
```

### Step 6 — Import Power Automate Flow

Recreate the flow manually following the architecture above, or import the exported flow package.

### Step 7 — Connect Power BI

Open `Workplace_Dashboard.pbix` → Update data source to your SharePoint URL → Refresh.

---

## 📊 Dashboard Preview

The Power BI dashboard provides:

- **KPI Cards**: Total Projects / Done / Pending / Last AI Processing
- **Donut Chart**: Projects by AI Status
- **Bar Chart**: Projects by Business Impact
- **Table**: Project list with AI-generated tags
- **Timeline**: Project creation over time

---

## 💼 Skills Demonstrated

This project showcases the following IT Workplace Engineer competencies:

- ✅ **PowerShell scripting** — M365, SharePoint Online, REST API integration
- ✅ **Power Automate** — Multi-step workflows, approvals, Forms/SharePoint connectors
- ✅ **AI Integration** — OpenAI GPT-4 API, JSON parsing, error handling
- ✅ **SharePoint Online** — List management, custom columns, PnP automation
- ✅ **Power BI** — DAX measures, SharePoint connector, dashboard design
- ✅ **Windows Task Scheduler** — Automated script execution
- ✅ **Technical documentation** — Architecture diagrams, installation guides
- ✅ **Agentic AI mindset** — End-to-end automated pipeline, zero manual intervention

---

## 👤 Author

**Junior BÉGON**
- LinkedIn: [linkedin.com/in/junior-b-563032163](https://www.linkedin.com/in/junior-b-563032163/)
- GitHub: [github.com/Alpha199777](https://github.com/Alpha199777)
- Tenant: `alone396.onmicrosoft.com` (demo environment)

---

## 📄 License

MIT License — Free to use and adapt for educational purposes.
