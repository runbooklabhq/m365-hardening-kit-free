<#
 M365 Hardening Kit: Emergency Top 10 - read-only checks (Runbook Lab)
 Uses Get-* cmdlets only. Changes nothing in your tenant.
 Requires: Microsoft.Graph, ExchangeOnlineManagement, MicrosoftTeams, Microsoft.Online.SharePoint.PowerShell (as needed).
 Connect first, e.g.:
   Connect-MgGraph -Scopes Policy.Read.All,Directory.Read.All,AuditLog.Read.All,RoleManagement.Read.Directory
   Connect-ExchangeOnline; Connect-IPPSSession; Connect-MicrosoftTeams; Connect-SPOService -Url https://<tenant>-admin.sharepoint.com
 Output: .\hardening-check-results.csv (ID, Control, Output or Error). Feed it to the m365-hardening-coach skill.
#>
$ErrorActionPreference = 'Stop'
$results = @()
function Invoke-Check($Id, $Title, [scriptblock]$Block) {
  try { $o = & $Block | Out-String -Width 400; $s = 'OK' } catch { $o = $_.Exception.Message; $s = 'ERROR' }
  Write-Host "[$Id] $Title -> $s"
  $script:results += [pscustomobject]@{ ID = $Id; Control = $Title; Status = $s; Output = $o.Trim() }
}

Invoke-Check 'E02' 'Require MFA for all users' { Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy | Select-Object IsEnabled; Get-MgIdentityConditionalAccessPolicy | Select-Object DisplayName, State }
Invoke-Check 'E03' 'Block legacy authentication' { Get-TransportConfig | Select-Object SmtpClientAuthenticationDisabled }
Invoke-Check 'E04' 'Reduce and separate admin accounts' { Get-MgDirectoryRoleMember -DirectoryRoleId (Get-MgDirectoryRole -Filter "displayName eq 'Global Administrator'").Id | ForEach-Object { $_.AdditionalProperties.userPrincipalName } }
Invoke-Check 'E05' 'Restrict user consent to applications' { Get-MgPolicyAuthorizationPolicy | Select-Object -ExpandProperty DefaultUserRolePermissions | Select-Object PermissionGrantPoliciesAssigned }
Invoke-Check 'E06' 'Confirm audit logging is on' { Get-AdminAuditLogConfig | Select-Object UnifiedAuditLogIngestionEnabled; Get-OrganizationConfig | Select-Object AuditDisabled }
Invoke-Check 'E07' 'Block automatic external email forwarding' { Get-HostedOutboundSpamFilterPolicy | Select-Object Name, AutoForwardingMode; Get-EXOMailbox -ResultSize Unlimited -Properties ForwardingSmtpAddress | Where-Object { $_.ForwardingSmtpAddress } | Select-Object Name, ForwardingSmtpAddress }
Invoke-Check 'E08' 'Apply the Standard preset security policy' { Get-EOPProtectionPolicyRule | Select-Object Name, State }
Invoke-Check 'E09' 'Set up SPF, DKIM and DMARC' { Get-DkimSigningConfig | Select-Object Domain, Enabled }

$results | Export-Csv -NoTypeInformation -Encoding UTF8 .\hardening-check-results.csv
Write-Host "Done: $($results.Count) checks -> hardening-check-results.csv"
