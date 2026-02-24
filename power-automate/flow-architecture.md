# ⚡ Power Automate Flow — Architecture

## Flow Name
Provisioning Automatique - Workplace

## Trigger
Microsoft Forms — New response submitted (PROJET-LION-2026 v2)

## Steps

| Step | Action | Details |
|------|--------|---------|
| 1 | Trigger | New Forms response |
| 2 | Get response details | Forms connector |
| 3 | Start approval | Approver: FirstNameLastName@alone396.onmicrosoft.com |
| 4 | Condition | `outputs('Démarrer_et_attendre_une_approbation')?['body/outcome']` == `Approve` |
| 5 ✅ | Create SharePoint item | List: Registre des Projets, AI_Status: Pending |
| 6 ✅ | Send confirmation email | Outlook V2 connector |
| 5 ❌ | End flow | No action on rejection |

## Key Fix — Condition Expression
Use the `fx` expression editor (not dynamic content) to reference the approval outcome:
```
outputs('Démarrer_et_attendre_une_approbation')?['body/outcome']
```
Compare with value: `Approve` (not `Approved`)

## Connectors Required
- Microsoft Forms
- Approvals (Standard)
- SharePoint
- Outlook (V2)
