param(
    [string]$TenantId = "341ce2be-83c2-4a03-9275-a0bc5073d0fd",
    [string]$ClientId = "67f23700-2020-4668-85d5-2ccc7de6cbc4",
    [string]$OutputPath = ".\EntraDashboard.html",
    [switch]$UseDeviceCode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-GraphTokenClientCredential {
    param(
        [Parameter(Mandatory = $true)][string]$TenantId,
        [Parameter(Mandatory = $true)][string]$ClientId
    )

    $secret = $env:GRAPH_CLIENT_SECRET
    if ([string]::IsNullOrWhiteSpace($secret)) {
        $secure = Read-Host "Enter app client secret for $ClientId" -AsSecureString
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try {
            $secret = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
        }
        finally {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }

    $tokenBody = @{
        grant_type    = "client_credentials"
        client_id     = $ClientId
        client_secret = $secret
        scope         = "https://graph.microsoft.com/.default"
    }

    $tokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $tokenResponse = Invoke-RestMethod -Method Post -Uri $tokenUri -Body $tokenBody -ContentType "application/x-www-form-urlencoded"
    return $tokenResponse.access_token
}

function Get-GraphTokenDeviceCode {
    param(
        [Parameter(Mandatory = $true)][string]$TenantId,
        [Parameter(Mandatory = $true)][string]$ClientId
    )

    # Confidential client apps require client_secret even for device code flow
    $secret = $env:GRAPH_CLIENT_SECRET
    if ([string]::IsNullOrWhiteSpace($secret)) {
        $secure = Read-Host "Enter app client secret for $ClientId" -AsSecureString
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try {
            $secret = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
        }
        finally {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }

    $deviceCodeBody = @{
        client_id     = $ClientId
        client_secret = $secret
        scope         = "https://graph.microsoft.com/.default offline_access"
    }

    $deviceCodeUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/devicecode"
    $deviceCode = Invoke-RestMethod -Method Post -Uri $deviceCodeUri -Body $deviceCodeBody -ContentType "application/x-www-form-urlencoded"
    Write-Host ""
    Write-Host $deviceCode.message -ForegroundColor Yellow
    Write-Host ""

    $tokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $pollBody = @{
        grant_type    = "urn:ietf:params:oauth:grant-type:device_code"
        client_id     = $ClientId
        client_secret = $secret
        device_code   = $deviceCode.device_code
    }

    $deadline = (Get-Date).AddSeconds([int]$deviceCode.expires_in)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds ([int]$deviceCode.interval)
        try {
            $tokenResponse = Invoke-RestMethod -Method Post -Uri $tokenUri -Body $pollBody -ContentType "application/x-www-form-urlencoded"
            if ($tokenResponse.access_token) {
                return $tokenResponse.access_token
            }
        }
        catch {
            $err = $_.ErrorDetails.Message
            if ($err -and ($err -match "authorization_pending|slow_down")) {
                continue
            }
            throw
        }
    }

    throw "Device code flow timed out."
}

function Invoke-GraphPaged {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][hashtable]$Headers,
        [int]$MaxItems = 200
    )

    $items = @()
    $next = $Uri

    while ($next -and $items.Count -lt $MaxItems) {
        $response = Invoke-RestMethod -Method Get -Uri $next -Headers $Headers
        $hasValue = $false
        if ($null -ne $response -and $response.PSObject.Properties.Match("value").Count -gt 0) {
            $hasValue = $true
        }

        if ($hasValue) {
            $items += @($response.value)
        }
        else {
            $items += $response
            break
        }

        if ($response.PSObject.Properties.Match("@odata.nextLink").Count -gt 0) {
            $next = [string]$response.'@odata.nextLink'
        }
        else {
            $next = $null
        }
    }

    if ($items.Count -gt $MaxItems) {
        return $items[0..($MaxItems - 1)]
    }
    return $items
}

function Get-GraphErrorMessage {
    param([object]$ExceptionRecord)

    $defaultMessage = ""
    if ($null -ne $ExceptionRecord -and $null -ne $ExceptionRecord.Exception) {
        if ($ExceptionRecord.Exception.PSObject.Properties.Match("Message").Count -gt 0) {
            $defaultMessage = [string]$ExceptionRecord.Exception.Message
        }
    }
    if ([string]::IsNullOrWhiteSpace($defaultMessage)) {
        $defaultMessage = "Graph request failed."
    }

    $details = $null
    if ($null -ne $ExceptionRecord -and $ExceptionRecord.PSObject.Properties.Match("ErrorDetails").Count -gt 0) {
        if ($null -ne $ExceptionRecord.ErrorDetails -and $ExceptionRecord.ErrorDetails.PSObject.Properties.Match("Message").Count -gt 0) {
            $details = $ExceptionRecord.ErrorDetails.Message
        }
    }
    if ([string]::IsNullOrWhiteSpace($details)) {
        return [pscustomobject]@{
            Code    = "Unknown"
            Message = $defaultMessage
        }
    }

    try {
        $obj = $details | ConvertFrom-Json
        return [pscustomobject]@{
            Code    = [string]$obj.error.code
            Message = [string]$obj.error.message
        }
    }
    catch {
        return [pscustomobject]@{
            Code    = "Unknown"
            Message = $details
        }
    }
}

function Invoke-GraphSafe {
    param(
        [Parameter(Mandatory = $true)][string]$Dataset,
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][hashtable]$Headers,
        [AllowEmptyCollection()][System.Collections.Generic.List[object]]$Errors,
        [int]$MaxItems = 200
    )

    try {
        return Invoke-GraphPaged -Uri $Uri -Headers $Headers -MaxItems $MaxItems
    }
    catch {
        $err = Get-GraphErrorMessage -ExceptionRecord $_
        $Errors.Add([pscustomobject]@{
            dataset = $Dataset
            code    = $err.Code
            message = $err.Message
            uri     = $Uri
        }) | Out-Null
        Write-Warning "Graph call failed for '$Dataset': $($err.Code) - $($err.Message)"
        return @()
    }
}

function ConvertTo-SafeHtml {
    param([string]$Text)
    if ($null -eq $Text) { return "" }
    return [System.Net.WebUtility]::HtmlEncode($Text)
}

function New-TableHtml {
    param(
        [string]$Title,
        [array]$Rows,
        [string[]]$Columns,
        [string]$EmptyMessage = "No records returned."
    )

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append("<div class='card'><h3>$(ConvertTo-SafeHtml $Title)</h3>")

    $rowList = @($Rows)
    if ($rowList.Count -eq 0) {
        [void]$sb.Append("<p class='muted'>$(ConvertTo-SafeHtml $EmptyMessage)</p></div>")
        return $sb.ToString()
    }

    [void]$sb.Append("<table><thead><tr>")
    foreach ($col in $Columns) {
        [void]$sb.Append("<th>$(ConvertTo-SafeHtml $col)</th>")
    }
    [void]$sb.Append("</tr></thead><tbody>")

    foreach ($row in $rowList) {
        [void]$sb.Append("<tr>")
        foreach ($col in $Columns) {
            $val = ""
            if ($null -ne $row) {
                if ($row -is [System.Collections.IDictionary] -and $row.Contains($col)) {
                    $val = $row[$col]
                }
                elseif ($row.PSObject.Properties.Match($col).Count -gt 0) {
                    $val = $row.$col
                }
            }
            if ($val -is [array]) { $val = ($val -join ", ") }
            if ($val -and $val.PSObject.Properties.Match("__html").Count -gt 0) {
                [void]$sb.Append("<td>$($val.__html)</td>")
            }
            else {
                [void]$sb.Append("<td>$(ConvertTo-SafeHtml ([string]$val))</td>")
            }
        }
        [void]$sb.Append("</tr>")
    }
    [void]$sb.Append("</tbody></table></div>")
    return $sb.ToString()
}

function New-HtmlLink {
    param(
        [string]$Text,
        [string]$Href
    )

    if ([string]::IsNullOrWhiteSpace($Href)) {
        return [pscustomobject]@{ __html = "" }
    }
    $safeText = ConvertTo-SafeHtml $Text
    $safeHref = ConvertTo-SafeHtml $Href
    return [pscustomobject]@{
        __html = "<a href='$safeHref' target='_blank' rel='noopener noreferrer'>$safeText</a>"
    }
}

function New-StatusBadge {
    param(
        [string]$Text,
        [ValidateSet("green", "yellow", "red", "gray")][string]$Tone = "gray"
    )

    $safeText = ConvertTo-SafeHtml $Text
    return [pscustomobject]@{
        __html = "<span class='status-badge status-$Tone'>$safeText</span>"
    }
}

function New-StatusCell {
    param(
        [string]$StatusText,
        [ValidateSet("green", "yellow", "red", "gray")][string]$Tone = "gray"
    )

    $safeStatus = ConvertTo-SafeHtml $StatusText
    $safeTone = ConvertTo-SafeHtml $Tone
    return [pscustomobject]@{
        __html = "<div class='status-cell'><span>$safeStatus</span><span class='status-word status-word-$safeTone'>$safeTone</span></div>"
    }
}

function Get-JwtPayload {
    param([string]$Jwt)

    if ([string]::IsNullOrWhiteSpace($Jwt)) { return $null }
    $parts = $Jwt.Split(".")
    if ($parts.Count -lt 2) { return $null }
    $payload = $parts[1].Replace("-", "+").Replace("_", "/")
    switch ($payload.Length % 4) {
        2 { $payload += "==" }
        3 { $payload += "=" }
    }
    try {
        $bytes = [System.Convert]::FromBase64String($payload)
        $json = [System.Text.Encoding]::UTF8.GetString($bytes)
        return $json | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function New-DashboardPageHtml {
    param(
        [string]$Title,
        [string]$Subtitle,
        [string]$NavHtml,
        [string]$BodyHtml,
        [string]$BannerHtml = ""
    )

    return @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$(ConvertTo-SafeHtml $Title)</title>
  <link rel="stylesheet" href="dashboard.css">
</head>
<body>
<nav class="topnav"></nav>
<div class="wrap">
  <div class="sub">$Subtitle</div>
  <div class="page-header"><h1>$(ConvertTo-SafeHtml $Title)</h1></div>
  $BannerHtml
  $BodyHtml
</div>
<script src="dashboard.js"></script>
</body>
</html>
"@
}

Write-Host "Authenticating to Microsoft Graph..."
$token = if ($UseDeviceCode) {
    Get-GraphTokenDeviceCode -TenantId $TenantId -ClientId $ClientId
}
else {
    Get-GraphTokenClientCredential -TenantId $TenantId -ClientId $ClientId
}

$portalBase = "https://entra.microsoft.com"
$signInListUrl = "$portalBase/#view/Microsoft_AAD_IAM/SignInsEventsV2Blade"
$tokenPayload = Get-JwtPayload -Jwt $token
$tokenRoles = @()
if ($null -ne $tokenPayload -and $tokenPayload.PSObject.Properties.Match("roles").Count -gt 0) {
    $tokenRoles = @($tokenPayload.roles)
}
Write-Host "Token app roles: $(@($tokenRoles).Count)"

$headers = @{
    Authorization      = "Bearer $token"
    "ConsistencyLevel" = "eventual"
}

Write-Host "Collecting Entra data..."

$apiErrors = [System.Collections.Generic.List[object]]::new()

$caPolicies = Invoke-GraphSafe -Dataset "Conditional Access Policies" -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies?`$top=100" -Headers $headers -Errors $apiErrors -MaxItems 200
$users = Invoke-GraphSafe -Dataset "Users" -Uri "https://graph.microsoft.com/v1.0/users?`$select=id,displayName,userPrincipalName,accountEnabled,createdDateTime&`$top=100" -Headers $headers -Errors $apiErrors -MaxItems 200
$groups = Invoke-GraphSafe -Dataset "Groups" -Uri "https://graph.microsoft.com/v1.0/groups?`$select=id,displayName,mailEnabled,securityEnabled,groupTypes,createdDateTime&`$top=100" -Headers $headers -Errors $apiErrors -MaxItems 200
$devices = Invoke-GraphSafe -Dataset "Devices" -Uri "https://graph.microsoft.com/v1.0/devices?`$select=id,displayName,operatingSystem,trustType,accountEnabled,approximateLastSignInDateTime&`$top=100" -Headers $headers -Errors $apiErrors -MaxItems 200
$servicePrincipals = Invoke-GraphSafe -Dataset "Enterprise Apps (Service Principals)" -Uri "https://graph.microsoft.com/v1.0/servicePrincipals?`$select=id,displayName,appId,servicePrincipalType,accountEnabled,createdDateTime&`$top=100" -Headers $headers -Errors $apiErrors -MaxItems 200
$appRegistrations = Invoke-GraphSafe -Dataset "App Registrations (Applications)" -Uri "https://graph.microsoft.com/v1.0/applications?`$select=id,displayName,appId,createdDateTime&`$top=100" -Headers $headers -Errors $apiErrors -MaxItems 200
$serviceHealth = Invoke-GraphSafe -Dataset "Service Health Overview" -Uri "https://graph.microsoft.com/v1.0/admin/serviceAnnouncement/healthOverviews" -Headers $headers -Errors $apiErrors -MaxItems 200
$serviceIssues = Invoke-GraphSafe -Dataset "Service Issues" -Uri "https://graph.microsoft.com/v1.0/admin/serviceAnnouncement/issues?`$top=50" -Headers $headers -Errors $apiErrors -MaxItems 100
$recentSignins = Invoke-GraphSafe -Dataset "Recent Sign-ins" -Uri "https://graph.microsoft.com/v1.0/auditLogs/signIns?`$select=id,createdDateTime,userDisplayName,userPrincipalName,appDisplayName,appId,ipAddress,status,conditionalAccessStatus&`$top=200&`$orderby=createdDateTime desc" -Headers $headers -Errors $apiErrors -MaxItems 200
$recentAudits = Invoke-GraphSafe -Dataset "Recent Directory Audits" -Uri "https://graph.microsoft.com/v1.0/auditLogs/directoryAudits?`$top=50&`$orderby=activityDateTime desc" -Headers $headers -Errors $apiErrors -MaxItems 50
$intuneManagedDevices = Invoke-GraphSafe -Dataset "Intune Managed Devices" -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$select=id,deviceName,operatingSystem,complianceState,managementState,lastSyncDateTime,userPrincipalName&`$top=100" -Headers $headers -Errors $apiErrors -MaxItems 200
$intuneCompliancePolicies = Invoke-GraphSafe -Dataset "Intune Compliance Policies" -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies?`$select=id,displayName,description,createdDateTime,lastModifiedDateTime&`$top=100" -Headers $headers -Errors $apiErrors -MaxItems 200
$intuneConfigProfiles = Invoke-GraphSafe -Dataset "Intune Configuration Profiles" -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations?`$select=id,displayName,description,createdDateTime,lastModifiedDateTime&`$top=100" -Headers $headers -Errors $apiErrors -MaxItems 200
$intuneMobileApps = Invoke-GraphSafe -Dataset "Intune Mobile Apps" -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps?`$select=id,displayName,publisher,isFeatured,createdDateTime,lastModifiedDateTime&`$top=100" -Headers $headers -Errors $apiErrors -MaxItems 200
$defenderIncidents = Invoke-GraphSafe -Dataset "Defender Incidents" -Uri "https://graph.microsoft.com/v1.0/security/incidents?`$top=50" -Headers $headers -Errors $apiErrors -MaxItems 200
$defenderAlerts = Invoke-GraphSafe -Dataset "Defender Alerts" -Uri "https://graph.microsoft.com/v1.0/security/alerts_v2?`$top=100" -Headers $headers -Errors $apiErrors -MaxItems 200
$defenderSecureScores = Invoke-GraphSafe -Dataset "Defender Secure Scores" -Uri "https://graph.microsoft.com/v1.0/security/secureScores?`$top=50" -Headers $headers -Errors $apiErrors -MaxItems 100

$summary = [ordered]@{
    "Conditional Access Policies" = @($caPolicies).Count
    "Users (sampled)"             = @($users).Count
    "Groups (sampled)"            = @($groups).Count
    "Devices (sampled)"           = @($devices).Count
    "Enterprise Apps (sampled)"   = @($servicePrincipals).Count
    "App Registrations (sampled)" = @($appRegistrations).Count
    "Intune Devices (sampled)"    = @($intuneManagedDevices).Count
    "Defender Incidents"          = @($defenderIncidents).Count
    "Service Health Workloads"    = @($serviceHealth).Count
    "Open Service Issues"         = @($serviceIssues | Where-Object { $_.status -ne "serviceRestored" }).Count
    "Recent Sign-ins"             = @($recentSignins).Count
    "Recent Directory Audits"     = @($recentAudits).Count
    "Token App Roles"             = @($tokenRoles).Count
    "Failed API Calls"            = @($apiErrors).Count
}

$summaryCards = [System.Text.StringBuilder]::new()
foreach ($item in $summary.GetEnumerator()) {
    [void]$summaryCards.Append("<div class='metric'><div class='metric-title'>$(ConvertTo-SafeHtml $item.Key)</div><div class='metric-value'>$($item.Value)</div></div>")
}

$caRows = foreach ($p in @($caPolicies)) {
    [pscustomobject]@{
        displayName      = New-HtmlLink -Text $p.displayName -Href "$portalBase/#view/Microsoft_AAD_ConditionalAccess/ConditionalAccessBlade/~/Policies/policyId/$($p.id)"
        state            = $p.state
        createdDateTime  = $p.createdDateTime
        modifiedDateTime = $p.modifiedDateTime
    }
}
$userRows = $users | Select-Object displayName, userPrincipalName, accountEnabled, createdDateTime
$groupRows = $groups | Select-Object displayName, mailEnabled, securityEnabled, groupTypes, createdDateTime
$deviceRows = foreach ($d in @($devices)) {
    [pscustomobject]@{
        displayName                   = New-HtmlLink -Text $d.displayName -Href "$portalBase/#view/Microsoft_AAD_Devices/DeviceDetailsMenuBlade/~/Properties/objectId/$($d.id)"
        operatingSystem               = $d.operatingSystem
        trustType                     = $d.trustType
        accountEnabled                = $d.accountEnabled
        approximateLastSignInDateTime = $d.approximateLastSignInDateTime
    }
}
$signinRows = foreach ($s in @($recentSignins)) {
    $statusText = ""
    if ($null -ne $s.status) {
        $statusCode = ""
        $statusReason = ""
        if ($s.status.PSObject.Properties.Match("errorCode").Count -gt 0) { $statusCode = [string]$s.status.errorCode }
        if ($s.status.PSObject.Properties.Match("failureReason").Count -gt 0) { $statusReason = [string]$s.status.failureReason }
        $statusText = if ([string]::IsNullOrWhiteSpace($statusReason)) { $statusCode } else { "$statusCode - $statusReason" }
    }
    [pscustomobject]@{
        createdDateTime         = $s.createdDateTime
        userPrincipalName       = $s.userPrincipalName
        appDisplayName          = $s.appDisplayName
        conditionalAccessStatus = $s.conditionalAccessStatus
        ipAddress               = $s.ipAddress
        status                  = $statusText
        signInLog               = New-HtmlLink -Text "Open log" -Href "$portalBase/#view/Microsoft_AAD_IAM/SignInDetails.ReactView/~/aadSignInId/$($s.id)"
    }
}

$caSigninRows = @($signinRows | Where-Object { $_.conditionalAccessStatus -and $_.conditionalAccessStatus -ne "notApplied" })

$spSigninsByAppId = @{}
foreach ($s in @($recentSignins)) {
    if (-not [string]::IsNullOrWhiteSpace([string]$s.appId)) {
        if (-not $spSigninsByAppId.ContainsKey($s.appId)) {
            $spSigninsByAppId[$s.appId] = New-Object System.Collections.ArrayList
        }
        [void]$spSigninsByAppId[$s.appId].Add($s)
    }
}

$spRows = foreach ($sp in @($servicePrincipals)) {
    $appId = [string]$sp.appId
    $matches = @()
    if ($spSigninsByAppId.ContainsKey($appId)) {
        $matches = @($spSigninsByAppId[$appId])
    }
    $latest = $matches | Sort-Object createdDateTime -Descending | Select-Object -First 1
    [pscustomobject]@{
        displayName      = New-HtmlLink -Text $sp.displayName -Href "$portalBase/#view/Microsoft_AAD_IAM/ManagedAppMenuBlade/~/Overview/objectId/$($sp.id)/appId/$($sp.appId)"
        servicePrincipal = $sp.servicePrincipalType
        accountEnabled   = $sp.accountEnabled
        createdDateTime  = $sp.createdDateTime
        signInCount      = @($matches).Count
        latestSignIn     = if ($latest) { $latest.createdDateTime } else { "" }
        latestSignInLog  = if ($latest) { New-HtmlLink -Text "Open log" -Href "$portalBase/#view/Microsoft_AAD_IAM/SignInDetails.ReactView/~/aadSignInId/$($latest.id)" } else { "" }
    }
}

$appRows = foreach ($app in @($appRegistrations)) {
    $appId = [string]$app.appId
    $matches = @()
    if ($spSigninsByAppId.ContainsKey($appId)) {
        $matches = @($spSigninsByAppId[$appId])
    }
    $latest = $matches | Sort-Object createdDateTime -Descending | Select-Object -First 1
    [pscustomobject]@{
        displayName     = New-HtmlLink -Text $app.displayName -Href "$portalBase/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/$($app.appId)"
        createdDateTime = $app.createdDateTime
        signInCount     = @($matches).Count
        latestSignIn    = if ($latest) { $latest.createdDateTime } else { "" }
        latestSignInLog = if ($latest) { New-HtmlLink -Text "Open log" -Href "$portalBase/#view/Microsoft_AAD_IAM/SignInDetails.ReactView/~/aadSignInId/$($latest.id)" } else { "" }
    }
}

$spSigninRows = foreach ($s in @($recentSignins | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.appId) })) {
    [pscustomobject]@{
        createdDateTime   = $s.createdDateTime
        appDisplayName    = $s.appDisplayName
        userPrincipalName = $s.userPrincipalName
        ipAddress         = $s.ipAddress
        signInLog         = New-HtmlLink -Text "Open log" -Href "$portalBase/#view/Microsoft_AAD_IAM/SignInDetails.ReactView/~/aadSignInId/$($s.id)"
    }
}

$appRegAppIds = @{}
foreach ($app in @($appRegistrations)) {
    if (-not [string]::IsNullOrWhiteSpace([string]$app.appId)) {
        $appRegAppIds[[string]$app.appId] = $true
    }
}

$appRegSigninRows = foreach ($s in @($recentSignins)) {
    if ($appRegAppIds.ContainsKey([string]$s.appId)) {
        [pscustomobject]@{
            createdDateTime   = $s.createdDateTime
            appDisplayName    = $s.appDisplayName
            userPrincipalName = $s.userPrincipalName
            ipAddress         = $s.ipAddress
            signInLog         = New-HtmlLink -Text "Open log" -Href "$portalBase/#view/Microsoft_AAD_IAM/SignInDetails.ReactView/~/aadSignInId/$($s.id)"
        }
    }
}

$intuneDeviceRows = $intuneManagedDevices | Select-Object deviceName, userPrincipalName, operatingSystem, complianceState, managementState, lastSyncDateTime
$intuneComplianceRows = $intuneCompliancePolicies | Select-Object displayName, description, createdDateTime, lastModifiedDateTime
$intuneConfigRows = $intuneConfigProfiles | Select-Object displayName, description, createdDateTime, lastModifiedDateTime
$intuneAppRows = $intuneMobileApps | Select-Object displayName, publisher, isFeatured, createdDateTime, lastModifiedDateTime

$defenderIncidentRows = foreach ($inc in @($defenderIncidents)) {
    $severity = ""
    $status = ""
    if ($inc.PSObject.Properties.Match("severity").Count -gt 0) { $severity = [string]$inc.severity }
    if ($inc.PSObject.Properties.Match("status").Count -gt 0) { $status = [string]$inc.status }
    $tone = "gray"
    if ($severity -match "high|critical" -or $status -match "active") { $tone = "red" }
    elseif ($severity -match "medium" -or $status -match "inProgress|redirected") { $tone = "yellow" }
    elseif ($status -match "resolved") { $tone = "green" }
    [pscustomobject]@{
        incidentId          = if ($inc.PSObject.Properties.Match("incidentId").Count -gt 0) { [string]$inc.incidentId } else { "" }
        displayName         = if ($inc.PSObject.Properties.Match("displayName").Count -gt 0) { [string]$inc.displayName } else { "" }
        severity            = New-StatusBadge -Text $severity -Tone $tone
        status              = New-StatusBadge -Text $status -Tone $tone
        classification      = if ($inc.PSObject.Properties.Match("classification").Count -gt 0) { [string]$inc.classification } else { "" }
        determination       = if ($inc.PSObject.Properties.Match("determination").Count -gt 0) { [string]$inc.determination } else { "" }
        createdDateTime     = if ($inc.PSObject.Properties.Match("createdDateTime").Count -gt 0) { [string]$inc.createdDateTime } else { "" }
        lastUpdateDateTime  = if ($inc.PSObject.Properties.Match("lastUpdateDateTime").Count -gt 0) { [string]$inc.lastUpdateDateTime } else { "" }
    }
}

$defenderAlertRows = foreach ($a in @($defenderAlerts)) {
    $severity = if ($a.PSObject.Properties.Match("severity").Count -gt 0) { [string]$a.severity } else { "" }
    $status = if ($a.PSObject.Properties.Match("status").Count -gt 0) { [string]$a.status } else { "" }
    $tone = "gray"
    if ($severity -match "high|critical") { $tone = "red" }
    elseif ($severity -match "medium") { $tone = "yellow" }
    elseif ($severity -match "low|informational") { $tone = "green" }
    [pscustomobject]@{
        createdDateTime    = if ($a.PSObject.Properties.Match("createdDateTime").Count -gt 0) { [string]$a.createdDateTime } else { "" }
        title              = if ($a.PSObject.Properties.Match("title").Count -gt 0) { [string]$a.title } else { "" }
        serviceSource      = if ($a.PSObject.Properties.Match("serviceSource").Count -gt 0) { [string]$a.serviceSource } else { "" }
        severity           = New-StatusBadge -Text $severity -Tone $tone
        status             = New-StatusBadge -Text $status -Tone $tone
        category           = if ($a.PSObject.Properties.Match("category").Count -gt 0) { [string]$a.category } else { "" }
    }
}

$defenderSecureScoreRows = $defenderSecureScores | Select-Object createdDateTime, currentScore, maxScore, activeUserCount, enabledServices

$healthRows = foreach ($h in @($serviceHealth)) {
    $statusText = [string]$h.status
    $tone = "gray"
    if ($statusText -match "serviceOperational") { $tone = "green" }
    elseif ($statusText -match "investigating|verifyingService|serviceDegradation|restoringService") { $tone = "yellow" }
    elseif ($statusText -match "serviceInterruption|extendedRecovery|falsePositive") { $tone = "red" }
    [pscustomobject]@{
        service = $h.service
        status  = New-StatusCell -StatusText $statusText -Tone $tone
    }
}

$issueRows = foreach ($i in @($serviceIssues)) {
    $severity = ""
    $statusText = ""
    $id = ""
    $title = ""
    $service = ""
    if ($null -ne $i) {
        if ($i.PSObject.Properties.Match("severity").Count -gt 0) { $severity = [string]$i.severity }
        if ($i.PSObject.Properties.Match("status").Count -gt 0) { $statusText = [string]$i.status }
        if ($i.PSObject.Properties.Match("id").Count -gt 0) { $id = [string]$i.id }
        if ($i.PSObject.Properties.Match("title").Count -gt 0) { $title = [string]$i.title }
        if ($i.PSObject.Properties.Match("service").Count -gt 0) { $service = [string]$i.service }
    }
    $tone = "gray"
    if ($severity -match "critical|high" -or $statusText -match "serviceInterruption") { $tone = "red" }
    elseif ($severity -match "medium|normal" -or $statusText -match "investigating|serviceDegradation|verifyingService|restoringService") { $tone = "yellow" }
    elseif ($statusText -match "serviceRestored|resolved") { $tone = "green" }
    [pscustomobject]@{
        id       = $id
        title    = $title
        service  = $service
        status   = New-StatusCell -StatusText $statusText -Tone $tone
        severity = $severity
    }
}
$auditRows = $recentAudits | Select-Object activityDateTime, activityDisplayName, initiatedBy, result, category
$errorRows = $apiErrors | Select-Object dataset, code, message, uri
$tokenRoleRows = foreach ($role in @($tokenRoles)) { [pscustomobject]@{ role = $role } }

$generated = (Get-Date).ToString("u")
$outputDirectory = Split-Path -Path $OutputPath -Parent
if ([string]::IsNullOrWhiteSpace($outputDirectory)) {
    $outputDirectory = "."
}
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($OutputPath)

$pages = @(
    [pscustomobject]@{
        Key      = "conditional-access"
        Title    = "Conditional Access"
        FileName = "$baseName.conditional-access.html"
        Content  = @"
<section class="section"><h2>Conditional Access</h2><div class="cards">
$(New-TableHtml -Title "Policies" -Rows $caRows -Columns @("displayName", "state", "createdDateTime", "modifiedDateTime"))
$(New-TableHtml -Title "Conditional Access Sign-in Logs (Recent)" -Rows $caSigninRows -Columns @("createdDateTime", "userPrincipalName", "appDisplayName", "conditionalAccessStatus", "ipAddress", "signInLog") -EmptyMessage "No Conditional Access sign-ins returned.")
</div></section>
"@
    },
    [pscustomobject]@{
        Key      = "users"
        Title    = "Users"
        FileName = "$baseName.users.html"
        Content  = @"
<section class="section"><h2>Users</h2><div class="cards">
$(New-TableHtml -Title "Users (Top 200)" -Rows $userRows -Columns @("displayName", "userPrincipalName", "accountEnabled", "createdDateTime"))
</div></section>
"@
    },
    [pscustomobject]@{
        Key      = "groups"
        Title    = "Groups"
        FileName = "$baseName.groups.html"
        Content  = @"
<section class="section"><h2>Groups</h2><div class="cards">
$(New-TableHtml -Title "Groups (Top 200)" -Rows $groupRows -Columns @("displayName", "mailEnabled", "securityEnabled", "groupTypes", "createdDateTime"))
</div></section>
"@
    },
    [pscustomobject]@{
        Key      = "devices"
        Title    = "Devices"
        FileName = "$baseName.devices.html"
        Content  = @"
<section class="section"><h2>Devices</h2><div class="cards">
$(New-TableHtml -Title "Devices (Top 200)" -Rows $deviceRows -Columns @("displayName", "operatingSystem", "trustType", "accountEnabled", "approximateLastSignInDateTime"))
</div></section>
"@
    },
    [pscustomobject]@{
        Key      = "enterprise-apps"
        Title    = "Enterprise Apps"
        FileName = "$baseName.enterprise-apps.html"
        Content  = @"
<section class="section"><h2>Enterprise Apps</h2><div class="cards">
$(New-TableHtml -Title "Enterprise Apps (Top 200)" -Rows $spRows -Columns @("displayName", "servicePrincipal", "accountEnabled", "createdDateTime", "signInCount", "latestSignIn", "latestSignInLog"))
$(New-TableHtml -Title "Enterprise App Sign-in Logs (Recent)" -Rows $spSigninRows -Columns @("createdDateTime", "appDisplayName", "userPrincipalName", "ipAddress", "signInLog") -EmptyMessage "No Enterprise App sign-ins returned.")
</div></section>
"@
    },
    [pscustomobject]@{
        Key      = "app-registrations"
        Title    = "App Registrations"
        FileName = "$baseName.app-registrations.html"
        Content  = @"
<section class="section"><h2>App Registrations</h2><div class="cards">
$(New-TableHtml -Title "App Registrations (Top 200)" -Rows $appRows -Columns @("displayName", "createdDateTime", "signInCount", "latestSignIn", "latestSignInLog"))
$(New-TableHtml -Title "App Registration Sign-in Logs (Recent)" -Rows $appRegSigninRows -Columns @("createdDateTime", "appDisplayName", "userPrincipalName", "ipAddress", "signInLog") -EmptyMessage "No App Registration sign-ins returned.")
</div></section>
"@
    },
    [pscustomobject]@{
        Key      = "monitoring-health"
        Title    = "Monitoring and Health"
        FileName = "$baseName.monitoring-health.html"
        Content  = @"
<section class="section"><h2>Monitoring and Health</h2><div class="cards">
$(New-TableHtml -Title "Service Health Overview" -Rows $healthRows -Columns @("service", "status"))
$(New-TableHtml -Title "Service Issues" -Rows $issueRows -Columns @("id", "title", "service", "status", "severity"))
$(New-TableHtml -Title "Entra Sign-in Logs (Recent)" -Rows $signinRows -Columns @("createdDateTime", "userPrincipalName", "appDisplayName", "conditionalAccessStatus", "ipAddress", "status", "signInLog"))
$(New-TableHtml -Title "Conditional Access Sign-in Logs (Recent)" -Rows $caSigninRows -Columns @("createdDateTime", "userPrincipalName", "appDisplayName", "conditionalAccessStatus", "ipAddress", "signInLog") -EmptyMessage "No Conditional Access sign-ins returned.")
$(New-TableHtml -Title "Token App Roles (from access token)" -Rows $tokenRoleRows -Columns @("role") -EmptyMessage "No app roles present in token.")
$(New-TableHtml -Title "Sign-in Logs Shortcut" -Rows @([pscustomobject]@{ page = (New-HtmlLink -Text "Open Entra Sign-in Logs" -Href $signInListUrl) }) -Columns @("page"))
$(New-TableHtml -Title "Recent Directory Audits" -Rows $auditRows -Columns @("activityDateTime", "activityDisplayName", "initiatedBy", "result", "category"))
$(New-TableHtml -Title "Permission/API Errors" -Rows $errorRows -Columns @("dataset", "code", "message", "uri") -EmptyMessage "No API errors detected.")
</div></section>
"@
    },
    [pscustomobject]@{
        Key      = "intune-home"
        Title    = "Intune Home"
        FileName = "$baseName.intune-home.html"
        Content  = @"
<section class="section"><h2>Intune Home</h2><div class="cards">
$(New-TableHtml -Title "Managed Devices (Top 200)" -Rows $intuneDeviceRows -Columns @("deviceName", "userPrincipalName", "operatingSystem", "complianceState", "managementState", "lastSyncDateTime"))
</div></section>
<section class="section"><h2>Intune Compliance</h2><div class="cards">
$(New-TableHtml -Title "Compliance Policies (Top 200)" -Rows $intuneComplianceRows -Columns @("displayName", "description", "createdDateTime", "lastModifiedDateTime"))
</div></section>
<section class="section"><h2>Intune Configuration</h2><div class="cards">
$(New-TableHtml -Title "Configuration Profiles (Top 200)" -Rows $intuneConfigRows -Columns @("displayName", "description", "createdDateTime", "lastModifiedDateTime"))
</div></section>
<section class="section"><h2>Intune Apps</h2><div class="cards">
$(New-TableHtml -Title "Mobile Apps (Top 200)" -Rows $intuneAppRows -Columns @("displayName", "publisher", "isFeatured", "createdDateTime", "lastModifiedDateTime"))
</div></section>
"@
    },
    [pscustomobject]@{
        Key      = "defender-home"
        Title    = "Defender Home"
        FileName = "$baseName.defender-home.html"
        Content  = @"
<section class="section"><h2>Defender Home</h2><div class="cards">
$(New-TableHtml -Title "Incidents (Top 200)" -Rows $defenderIncidentRows -Columns @("incidentId", "displayName", "severity", "status", "classification", "determination", "createdDateTime", "lastUpdateDateTime"))
</div></section>
<section class="section"><h2>Defender Alerts</h2><div class="cards">
$(New-TableHtml -Title "Alerts (Top 200)" -Rows $defenderAlertRows -Columns @("createdDateTime", "title", "serviceSource", "severity", "status", "category"))
</div></section>
<section class="section"><h2>Defender Secure Scores</h2><div class="cards">
$(New-TableHtml -Title "Secure Scores (Top 100)" -Rows $defenderSecureScoreRows -Columns @("createdDateTime", "currentScore", "maxScore", "activeUserCount", "enabledServices"))
</div></section>
"@
    }
)

$indexName = [System.IO.Path]::GetFileName($OutputPath)
$allNavLinks = @("<a href=`"$indexName`">Home</a>")
foreach ($page in $pages) {
    $allNavLinks += "<a href=`"$($page.FileName)`">$([System.Net.WebUtility]::HtmlEncode($page.Title))</a>"
}
$navHtml = $allNavLinks -join [Environment]::NewLine
$bannerHtml = if (@($apiErrors).Count -gt 0) { "<div class='warn'>Some Graph endpoints failed due to missing permissions or access restrictions. Check Monitoring and Health -> Permission/API Errors.</div>" } else { "" }

foreach ($page in $pages) {
    $pageHtml = New-DashboardPageHtml `
        -Title "Entra Dashboard - $($page.Title)" `
        -Subtitle "Generated: $generated" `
        -NavHtml $navHtml `
        -BodyHtml $page.Content `
        -BannerHtml $bannerHtml

    $pagePath = Join-Path -Path $outputDirectory -ChildPath $page.FileName
    $pageHtml | Out-File -FilePath $pagePath -Encoding UTF8
}

$menuLinks = [System.Text.StringBuilder]::new()
foreach ($page in $pages) {
    [void]$menuLinks.Append("<a class='menu-link' href='$($page.FileName)'>$([System.Net.WebUtility]::HtmlEncode($page.Title))</a>")
}

$indexBody = @"
<section class="section">
  <h2>Sections</h2>
  <div class="cards">
    <div class="menu-grid">
      $($menuLinks.ToString())
    </div>
  </div>
</section>
"@

$indexHtml = New-DashboardPageHtml `
    -Title "Entra Dashboard" `
    -Subtitle "Generated: $generated" `
    -NavHtml $navHtml `
    -BodyHtml $indexBody `
    -BannerHtml $bannerHtml

$indexHtml | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "Dashboard main page generated: $OutputPath"
Write-Host "Dashboard section pages generated in: $(Resolve-Path $outputDirectory)"
Write-Host "Tip: Use -UseDeviceCode if your app registration does not have a client secret."
