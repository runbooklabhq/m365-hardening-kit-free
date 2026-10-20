# M365 Hardening Kit: Emergency Top 10 (free)

The ten Microsoft 365 security controls to do first, as a ready-to-run project: guide, Jira backlog, tracker and read-only PowerShell checks.

| File | What it is |
|---|---|
| `m365-hardening-kit-emergency-top-10-guide.md` | Why, steps, check, verify, licence and effort for each control |
| `m365-hardening-kit-emergency-top-10-jira-import.csv` | Jira Cloud import: epics + stories with parent links, priority, sprint and labels |
| `m365-hardening-kit-emergency-top-10-tracker.csv` | Same backlog for Planner, Azure DevOps, Excel or Linear |
| `m365-hardening-kit-emergency-top-10-readonly-checks.ps1` | Get-* cmdlets only. Changes nothing. Writes `hardening-check-results.csv` |

Controls: break-glass accounts · MFA for all users · block legacy auth · fewer admins · restrict app consent · audit log · block external forwarding · Standard preset policy · SPF/DKIM/DMARC · SSPR + banned passwords.

## Import into Jira
Jira Cloud > Settings > System > External system import > CSV. Map `Issue ID` and `Parent` so stories land under their epics. If the Sprint column does not map in your project, filter by the `sprint-1` label and bulk-move.

## Run the checks
```powershell
Install-Module Microsoft.Graph, ExchangeOnlineManagement -Scope CurrentUser
Connect-MgGraph -Scopes Policy.Read.All,Directory.Read.All,RoleManagement.Read.Directory
Connect-ExchangeOnline
./m365-hardening-kit-emergency-top-10-readonly-checks.ps1
```

## Next: the full kit
**M365 Hardening Kit: Complete** adds 48 controls in Sprints 2-5 (Entra ID, Exchange Online, Teams, SharePoint/OneDrive, Purview), 48 read-only checks, and the `m365-hardening-coach` Claude skill that turns your check results into a prioritised plan and a management summary. Includes the two late-2026 deadlines: Teams external file sharing default (MC1479514) and SMTP AUTH Basic auth off by default.
→ https://kritikos12.gumroad.com/l/m365-hardening-kit?utm_source=free-kit

MIT licence. Not affiliated with or endorsed by Microsoft. Test changes in Report-only or on a pilot group first.
