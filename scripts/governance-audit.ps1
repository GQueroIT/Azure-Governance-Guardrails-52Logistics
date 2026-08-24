# 52 Logistics Governance Audit
# Collects governance and security evidence from the Azure environment

$account = az account show | ConvertFrom-Json

$subscriptionId = $account.id
$subscriptionName = $account.name
$tenantId = $account.tenantId
$currentUser = $account.user.name

Write-Host ""
Write-Host "52 Logistics Governance Audit"
Write-Host "-----------------------------"
Write-Host "Subscription: $subscriptionName"
Write-Host "Subscription ID: $subscriptionId"
Write-Host "Tenant ID: $tenantId"
Write-Host "Signed in as: $currentUser"
Write-Host ""

Write-Host "Azure Policy Assignments"
Write-Host "------------------------"

$policyassignments = az policy assignment list | ConvertFrom-Json

foreach ($policy in $policyAssignments) {
    Write-Host "Name: $($policy.name)"
    Write-Host "Scope: $($policy.scope)"
    Write-Host "Policy Definition ID: $($policy.policyDefinitionId)"
    Write-Host ""
}

Write-Host "RBAC Assignments"
Write-Host "----------------"

$rbacAssignments = az role assignment list --all --query "[].{Principal:principalName,Role:roleDefinitionName,Scope:scope}" --output json | ConvertFrom-Json

foreach ($assignment in $rbacAssignments) {
    Write-Host "Principal: $($assignment.principal)"
    Write-Host "Role: $($assignment.role)"
    Write-Host "Scope: $($assignment.scope)"
    Write-Host ""
}

Write-Host "Management Lock Verification"
Write-Host "----------------------------"

$locks = az lock list --resource-group "52logistics-rg" --output json | ConvertFrom-Json

$expectedLock = $locks | Where-Object {
    $_.name -eq "rg_delete_lock"
}

if ($null -ne $expectedLock) {
    Write-Host "Status: PASS"
    Write-Host "Lock Name: $($expectedLock.name)"
    Write-Host "Lock Level: $($expectedLock.level)"
}
else {
    Write-Host "Status: FAIL"
    Write-Host "Expected management lock was not found."
}
Write-Host ""

Write-Host "Policy Compliance Verification"
Write-Host "------------------------------"

$requiredPolicies = @(
    "required-tag"
    "allowed-locations"
    "Allowed virtual machine size SKUs"
)

$policyNames = $policyAssignments.name

$policyPassCount = 0

foreach ($requiredPolicy in $requiredPolicies) {

    if ($policyNames -contains $requiredPolicy) {
        Write-Host "$requiredPolicy : PASS"
        $policyPassCount++
    }
    else {
        Write-Host "$requiredPolicy : FAIL"
    }
}
Write-Host ""

Write-Host "Government Audit Summary"
Write-Host "------------------------"

Write-Host "Policies Passed: $policyPassCount / $($requiredPolicies.count)"

if ($null -ne $expectedLock) {
    Write-Host "Management Lock: PASS"
    $lockStatus = $true
}
else {
    Write-Host "Management Lock: Fail"
    $lockStatus = $false
}

if (($policyPassCount -eq $requiredPolicies.count) -and $lockStatus) {
    Write-Host ""
    Write-Host "Governance Status: Healthy"
}
else {
    Write-Host ""
    Write-Host "Governance Status: ATTENTION REQUIRED"
}

Write-Host ""