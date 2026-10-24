# M365 Hardening Kit: Emergency Top 10

_Version 1.0_

The ten Microsoft 365 controls to do first, in one sprint. Free. Each control has why, steps, a read-only PowerShell check where one exists, how to verify, licence and effort. Continue with the Extended kit (Sprints 2-5, 48 controls).

Read-only checks: run `m365-hardening-kit-emergency-top-10-readonly-checks.ps1` (Get-* cmdlets only, changes nothing).

| # | Control | Area | Sprint | Priority | Effort |
|---|---|---|---|---|---|
| E01 | Create two break-glass (emergency access) accounts | Identity & access (Entra ID) | Sprint 1 - Emergency | Highest | 30 min |
| E02 | Require MFA for all users | Identity & access (Entra ID) | Sprint 1 - Emergency | Highest | 1-2 h |
| E03 | Block legacy authentication | Identity & access (Entra ID) | Sprint 1 - Emergency | Highest | 1 h |
| E04 | Reduce and separate admin accounts | Identity & access (Entra ID) | Sprint 1 - Emergency | High | 1-2 h |
| E05 | Restrict user consent to applications | Identity & access (Entra ID) | Sprint 1 - Emergency | High | 30 min |
| E06 | Confirm audit logging is on | Audit & governance | Sprint 1 - Emergency | High | 15 min |
| E07 | Block automatic external email forwarding | Exchange Online & email security | Sprint 1 - Emergency | High | 30 min |
| E08 | Apply the Standard preset security policy | Exchange Online & email security | Sprint 1 - Emergency | High | 30 min |
| E09 | Set up SPF, DKIM and DMARC | Exchange Online & email security | Sprint 1 - Emergency | High | 1 h + DNS wait |
| E10 | Self-service password reset with banned passwords | Identity & access (Entra ID) | Sprint 1 - Emergency | Medium | 1 h |

## E01. Create two break-glass (emergency access) accounts

**Why:** If Conditional Access or MFA is misconfigured you can lock every admin out of the tenant. Two cloud-only emergency accounts keep a way back in.

**Steps:**
1. Create two cloud-only accounts on the *.onmicrosoft.com domain with the Global Administrator role.
2. Give them long random passwords or FIDO2 keys stored in two separate secure locations.
3. Exclude both accounts from every Conditional Access policy.
4. Create an alert for any sign-in by these accounts.

**Verify:** Both accounts exist, are excluded from all CA policies and a sign-in alert fires on a test sign-in.

**Licence:** Any · **Effort:** 30 min · **Priority:** Highest · **Sprint 1 - Emergency**

## E02. Require MFA for all users

**Why:** Most account takeovers start with a stolen or sprayed password. MFA blocks the large majority of them.

**Steps:**
1. No Entra ID P1: turn on Security defaults (Entra admin center > Overview > Properties > Manage security defaults).
2. With Entra ID P1: create a Conditional Access policy requiring MFA for all users and all cloud apps, excluding the break-glass accounts.
3. Start in Report-only mode for a few days, check sign-in logs, then switch to On.
4. Require phishing-resistant MFA for admin roles where possible.

**Check (read-only PowerShell):**

```powershell
Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy | Select-Object IsEnabled; Get-MgIdentityConditionalAccessPolicy | Select-Object DisplayName, State
```

**Verify:** Sign-in logs show MFA satisfied for interactive sign-ins; no user is excluded except break-glass accounts.

**Licence:** Free (Security defaults) or Entra ID P1 (Conditional Access) · **Effort:** 1-2 h · **Priority:** Highest · **Sprint 1 - Emergency**

## E03. Block legacy authentication

**Why:** Legacy protocols (basic auth over IMAP, POP, SMTP AUTH, older Office clients) cannot do MFA and are the main path for password-spray attacks.

**Steps:**
1. Check Entra sign-in logs filtered by Client app = legacy clients to find who still uses them.
2. Create a Conditional Access policy: all users, all cloud apps, client apps = Exchange ActiveSync + Other clients, grant = Block (exclude break-glass).
3. Run in Report-only first, fix remaining users, then turn On.
4. Disable SMTP AUTH at the organisation level unless a device really needs it.

**Check (read-only PowerShell):**

```powershell
$sd = (Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy).IsEnabled; "Security defaults enabled: $sd"; $ca = @(Get-MgIdentityConditionalAccessPolicy -All | Where-Object { ($_.Conditions.ClientAppTypes -contains 'exchangeActiveSync' -or $_.Conditions.ClientAppTypes -contains 'other') -and $_.GrantControls.BuiltInControls -contains 'block' }); if ($ca.Count -eq 0) { 'CA policies blocking legacy clients: none found' } else { $ca | ForEach-Object { "CA policy blocking legacy clients: $($_.DisplayName) [state: $($_.State)]" } }; "SMTP AUTH disabled org-wide: $((Get-TransportConfig).SmtpClientAuthenticationDisabled)"
```

**Verify:** A Conditional Access policy that blocks Exchange ActiveSync + Other clients is On (state: enabled), or Security defaults are enabled; and Entra sign-in logs show no successful legacy-auth sign-ins in the last 7 days.

**Licence:** Entra ID P1 (or Security defaults) · **Effort:** 1 h · **Priority:** Highest · **Sprint 1 - Emergency**

## E04. Reduce and separate admin accounts

**Why:** Every Global Administrator is a full-tenant compromise if phished. Daily mail use on an admin account multiplies the risk.

**Steps:**
1. List all users with privileged roles (Entra admin center > Roles and administrators).
2. Keep 2-4 Global Administrators; move others to least-privilege roles (e.g. Exchange or User Administrator).
3. Use separate cloud-only admin accounts with no mailbox for admin work.
4. With Entra ID P2, make roles eligible through Privileged Identity Management (PIM).

**Check (read-only PowerShell):**

```powershell
Get-MgDirectoryRoleMember -DirectoryRoleId (Get-MgDirectoryRole -Filter "displayName eq 'Global Administrator'").Id | ForEach-Object { $_.AdditionalProperties.userPrincipalName }
```

**Verify:** 2-4 Global Admins, all cloud-only, none used for daily email.

**Licence:** Any (PIM needs Entra ID P2) · **Effort:** 1-2 h · **Priority:** High · **Sprint 1 - Emergency**

## E05. Restrict user consent to applications

**Why:** Consent-phishing apps get mailbox and file access without a password. Unrestricted user consent lets any user grant it.

**Steps:**
1. Entra admin center > Enterprise applications > Consent and permissions.
2. Allow user consent only for apps from verified publishers for low-impact permissions, or disable user consent.
3. Turn on the admin consent workflow so users can request access.
4. Review existing app grants for unexpected high-privilege permissions.

**Check (read-only PowerShell):**

```powershell
Get-MgPolicyAuthorizationPolicy | Select-Object -ExpandProperty DefaultUserRolePermissions | Select-Object PermissionGrantPoliciesAssigned
```

**Verify:** User consent setting is restricted and the admin consent workflow is on.

**Licence:** Any · **Effort:** 30 min · **Priority:** High · **Sprint 1 - Emergency**

## E06. Confirm audit logging is on

**Why:** Without the unified audit log there is no evidence to investigate an incident.

**Steps:**
1. Microsoft Purview portal > Audit: confirm auditing is on (start recording if prompted).
2. Confirm mailbox auditing is enabled by default for the organisation.
3. Note your audit retention period for your license.

**Check (read-only PowerShell):**

```powershell
Get-AdminAuditLogConfig | Select-Object UnifiedAuditLogIngestionEnabled; Get-OrganizationConfig | Select-Object AuditDisabled
```

**Verify:** An audit search returns events from the last 24 hours.

**Licence:** Any (retention depends on license) · **Effort:** 15 min · **Priority:** High · **Sprint 1 - Emergency**

## E07. Block automatic external email forwarding

**Why:** Attackers who take over a mailbox add forwarding rules to copy mail out silently.

**Steps:**
1. Microsoft Defender portal > Email & collaboration > Policies > Anti-spam > Outbound policy.
2. Set automatic forwarding to Off for everyone; create a scoped exception policy only for approved mailboxes.
3. Review existing inbox rules and mailbox forwarding for external addresses.

**Check (read-only PowerShell):**

```powershell
Get-HostedOutboundSpamFilterPolicy | Select-Object Name, AutoForwardingMode; Get-EXOMailbox -ResultSize Unlimited -Properties ForwardingSmtpAddress | Where-Object { $_.ForwardingSmtpAddress } | Select-Object Name, ForwardingSmtpAddress
```

**Verify:** A test inbox rule forwarding to an external address is blocked; no unapproved forwarding remains.

**Licence:** Exchange Online · **Effort:** 30 min · **Priority:** High · **Sprint 1 - Emergency**

## E08. Apply the Standard preset security policy

**Why:** Microsoft's preset policies apply recommended anti-phishing, anti-malware, Safe Links and Safe Attachments settings in one step and update with new recommendations.

**Steps:**
1. Microsoft Defender portal > Email & collaboration > Policies > Preset security policies.
2. Turn on Standard protection for all recipients (Strict for executives and finance if you can).
3. With Defender for Office 365, Safe Links and Safe Attachments are included.

**Check (read-only PowerShell):**

```powershell
Get-EOPProtectionPolicyRule | Select-Object Name, State
```

**Verify:** Preset policy shows On and covers all recipients.

**Licence:** EOP (Defender for Office 365 for Safe Links/Attachments) · **Effort:** 30 min · **Priority:** High · **Sprint 1 - Emergency**

## E09. Set up SPF, DKIM and DMARC

**Why:** Without email authentication anyone can send mail that appears to come from your domain.

**Steps:**
1. Publish one SPF record listing every service that sends as your domain.
2. Enable DKIM signing for each custom domain in the Defender portal and publish the two CNAME records.
3. Publish DMARC with p=none and a reporting address, review reports for 2-4 weeks, then move to quarantine.

**Check (read-only PowerShell):**

```powershell
Get-DkimSigningConfig | Select-Object Domain, Enabled
```

**Verify:** A message header shows spf=pass, dkim=pass, dmarc=pass.

**Licence:** Any · **Effort:** 1 h + DNS wait · **Priority:** High · **Sprint 1 - Emergency**

## E10. Self-service password reset with banned passwords

**Why:** SSPR cuts helpdesk-assisted resets (a social-engineering target) and banned-password lists stop the most guessed passwords.

**Steps:**
1. Entra admin center > Protection > Password reset: enable for all users with two methods.
2. Use combined security-info registration so users register MFA and SSPR together.
3. Add your company and product names to the custom banned password list (Entra Password Protection).

**Verify:** A test user can reset a password with two methods; a banned password is rejected.

**Licence:** Entra ID P1 for SSPR with on-prem writeback and custom banned list · **Effort:** 1 h · **Priority:** Medium · **Sprint 1 - Emergency**

---
Not affiliated with or endorsed by Microsoft. Test every change in Report-only or on a pilot group first. Licence names and portal paths change; check Microsoft Learn if a menu has moved.
