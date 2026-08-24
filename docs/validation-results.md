# Governance Validation Results

## 52 Logistics Azure Governance Guardrails

**Project:** Azure Governance Guardrails – 52 Logistics  
**Platform:** Microsoft Azure  
**Infrastructure as Code:** Terraform  
**Validation Tools:** Azure CLI, PowerShell, Azure Portal  
**Status:** V1 Validation Complete

---

## Purpose

This document records the validation tests performed against the 52 Logistics Azure governance environment.

The purpose of testing was to verify that the controls deployed through Terraform behaved as designed in the live Azure environment.

Testing included both positive and negative scenarios.

Positive testing confirmed that authorized operations could be completed successfully.

Negative testing intentionally attempted operations that should be prevented by RBAC, Azure Policy, or management locks.

Additional tests simulated changes to governance controls outside Terraform to validate monitoring, alerting, drift detection, and remediation.

---

## Validation Method

The environment was not considered successfully validated based only on a successful `terraform apply`.

Controls were independently tested using:

- Azure CLI
- PowerShell
- Azure Portal
- Azure Activity Log
- Azure Monitor
- Email notifications
- Terraform plan and state refresh

The validation process followed this general workflow:

1. Deploy the governance control with Terraform.
2. Verify that the control exists in Azure.
3. Attempt an operation that should be allowed or denied.
4. Capture the Azure response.
5. Verify monitoring or alerting where applicable.
6. Introduce out-of-band changes where required.
7. Use Terraform to detect configuration drift.
8. Restore the intended configuration.
9. Run the PowerShell governance audit.
10. Confirm the environment returned to a healthy baseline.

---

# Validation Summary

| ID | Control | Test | Result |
|---|---|---|---|
| VAL-01 | Allowed Locations | Deploy resource in unapproved region | PASS |
| VAL-02 | Required Tag | Deploy resource without required tag | PASS |
| VAL-03 | Allowed VM SKUs | Deploy VM using unapproved SKU | PASS |
| VAL-04 | RBAC | Create resource group with Reader at subscription | PASS |
| VAL-05 | RBAC | Deploy resource with Contributor at RG | PASS |
| VAL-06 | Management Lock | Delete protected resource | PASS |
| VAL-07 | RBAC / Lock | Contributor attempts lock deletion | PASS |
| VAL-08 | Monitoring | Detect management lock deletion | PASS |
| VAL-09 | Monitoring | Detect policy assignment deletion | PASS |
| VAL-10 | Alerting | Deliver governance alert notification | PASS |
| VAL-11 | Activity Log | Record governance change and caller | PASS |
| VAL-12 | Terraform | Detect out-of-band policy deletion | PASS |
| VAL-13 | Terraform | Restore deleted governance control | PASS |
| VAL-14 | PowerShell | Validate governance baseline | PASS |

**Final Validation Status: PASS**

---

# VAL-01 — Allowed Locations Policy

## Objective

Verify that Azure Policy prevents resources from being deployed outside the approved Azure regions.

## Control

**Policy Assignment:** `allowed-locations`

**Approved Regions:**

- `eastus`
- `eastus2`

**Effect:** Deny

## Test Procedure

A storage account deployment was attempted using an Azure region outside the approved location list.

The deployment was performed using Azure CLI so that policy enforcement could be validated independently from Terraform.

The resource included the required environment tag so that the location policy could be isolated during testing.

## Expected Result

Azure Policy should reject the deployment because the requested location is not included in the approved region list.

## Actual Result

Azure rejected the resource deployment.

The response included:

`ResourceDisallowedByPolicy`

Azure identified the policy responsible for the denial as:

`Allowed locations`

The policy evaluation showed that the requested location was not contained within the approved values:

`eastus`

`eastus2`

## Result

**PASS**

The Allowed Locations policy successfully prevented deployment outside the approved Azure regions.

## Evidence

Screenshot:

`evidence/allowed-location-denied.png`

---

# VAL-02 — Required Tag Policy

## Objective

Verify that Azure Policy prevents deployment of resources that do not contain the required organizational tag.

## Control

**Required Tag:**

`Environment = Production`

**Effect:** Deny

## Test Procedure

A storage account deployment was attempted in an approved Azure region without supplying the required `Environment` tag.

Using an approved region prevented the Allowed Locations policy from interfering with the test.

## Expected Result

Azure Policy should reject the resource because the required tag is missing.

## Actual Result

Azure rejected the deployment with:

`RequestDisallowedByPolicy`

The policy evaluation identified:

`tags[Environment]`

The returned value was:

`null`

The expected value was:

`Production`

## Result

**PASS**

The required-tag policy successfully prevented deployment of a resource that did not meet the tagging standard.

## Evidence

Screenshot:

`evidence/tagging-policy-denied.png`

# VAL-03 — Allowed Virtual Machine SKU Policy

## Objective

Verify that Azure Policy prevents deployment of virtual machines using SKUs that are outside the approved organizational standard.

## Control

**Policy Assignment:** `Allowed virtual machine size SKUs`

**Approved VM SKUs:**

- `Standard_B1s`
- `Standard_B2s`

**Effect:** Deny

## Test Procedure

A virtual machine deployment was attempted using:

`Standard_D2s_v5`

The deployment used an approved Azure region and included the required `Environment = Production` tag.

This allowed the VM SKU policy to be tested without intentionally violating the location or tagging policies.

## Expected Result

Azure Policy should reject the virtual machine because `Standard_D2s_v5` is not included in the approved SKU list.

## Actual Result

Azure rejected the deployment.

The response identified:

`Allowed virtual machine size SKUs`

with the policy effect:

`Deny`

The requested SKU was outside the approved list.

## Result

**PASS**

The VM SKU policy successfully prevented deployment of an unapproved virtual machine size.

## Evidence

Screenshot:

`evidence/vm-sku-policy-denied.png`

---

# VAL-04 — RBAC Subscription Scope Restriction

## Objective

Verify that a user with Reader permissions at the subscription scope cannot perform resource creation operations that require write permissions at that scope.

## Control

The test identity was assigned:

**Role:** Reader  
**Scope:** Subscription

The same identity also had Contributor permissions at the designated `52logistics-rg` resource group.

## Test Procedure

The test identity authenticated to Azure separately from the subscription Owner account.

While operating as the test identity, an attempt was made to create a new resource group at subscription scope.

## Expected Result

The operation should fail because Reader provides visibility but does not provide permission to create resource groups.

## Actual Result

Azure rejected the operation with:

`AuthorizationFailed`

The response stated that the identity did not have authorization to perform:

`Microsoft.Resources/subscriptions/resourceGroups/write`

## Result

**PASS**

The test identity could not perform a write operation outside its authorized Contributor scope.

## Evidence

Screenshot:

`evidence/rbac-subscription-create-denied.png`

---

# VAL-05 — RBAC Resource Group Contributor Access

## Objective

Verify that the same restricted identity can successfully manage resources within the resource group where Contributor permissions were assigned.

## Control

The test identity was assigned:

**Role:** Contributor  
**Scope:** `52logistics-rg`

## Test Procedure

While authenticated as the test identity, a storage account was deployed inside:

`52logistics-rg`

The deployment was configured to comply with the existing governance policies:

**Location:** `eastus`

**Tag:** `Environment = Production`

## Expected Result

The deployment should succeed because:

- The identity has Contributor permissions at the resource group.
- The requested region is approved.
- The required tag is present.

## Actual Result

The storage account was created successfully.

## Result

**PASS**

The test demonstrated that RBAC restricted the identity based on scope without preventing legitimate operations inside the authorized resource group.

Together, VAL-04 and VAL-05 demonstrate the intended least-privilege access model:

Subscription
    |
    +-- Reader
    |   +-- Visibility across subscription
    |   +-- No subscription-level resource creation
    |
    +-- 52logistics-rg
        |
        +-- Contributor
            +-- Resource management permitted

## Evidence

Screenshot:

`evidence/rbac-rg-contributor-deployment-success.png`

---

# VAL-06 — Management Lock Resource Protection

## Objective

Verify that the `CanNotDelete` management lock prevents deletion of resources even when the authenticated identity has Contributor permissions to manage the resource.

## Control

**Lock Name:** `rg_delete_lock`

**Lock Level:** `CanNotDelete`

**Scope:** `52logistics-rg`

## Test Procedure

While authenticated as the Contributor test identity, an attempt was made to delete the storage account that had been successfully created during VAL-05.

The identity had sufficient RBAC permissions to manage resources within the resource group.

## Expected Result

RBAC should authorize the identity to manage the resource, but the inherited management lock should prevent deletion.

## Actual Result

Azure rejected the deletion with:

`ScopeLocked`

Azure reported that the resource could not be deleted because the resource group scope was locked.

## Result

**PASS**

The management lock successfully prevented deletion despite the user's Contributor permissions.

This demonstrated that RBAC authorization does not override an Azure management lock.

## Evidence

Screenshot:

`evidence/rbac-contributor-delete-blocked-by-lock.png`

---

# VAL-07 — Contributor Cannot Remove Management Lock

## Objective

Verify that the workload Contributor cannot bypass resource protection by removing the management lock.

## Control

The test identity had:

**Reader:** Subscription scope

**Contributor:** `52logistics-rg`

The resource group was protected by:

`rg_delete_lock`

## Test Procedure

While authenticated as the Contributor test identity, an attempt was made to delete the management lock protecting `52logistics-rg`.

## Expected Result

The operation should fail if the identity does not have authorization to manage the governance lock.

## Actual Result

Azure returned:

`AuthorizationFailed`

The response stated that the identity did not have authorization to perform:

`Microsoft.Authorization/locks/delete`

## Result

**PASS**

The Contributor could manage workloads inside the resource group but could not remove the governance control protecting those workloads.

This demonstrated separation between workload administration and governance administration.

VAL-06 and VAL-07 also demonstrated two different types of Azure enforcement:

`ScopeLocked`

The identity was authorized to perform the resource operation through RBAC, but a management lock prevented the action.

`AuthorizationFailed`

The identity did not have the required RBAC permission to perform the requested governance operation.

## Evidence

Screenshot:

`evidence/rbac-contributor-lock-enforcement.png`

# VAL-08 — Management Lock Deletion Monitoring

## Objective

Verify that Azure monitoring provides visibility when the management lock protecting the environment is removed.

## Control

**Protected Scope:** `52logistics-rg`

**Management Lock:** `rg_delete_lock`

**Monitoring:** Azure Monitor Activity Log Alert

**Notification:** Azure Monitor Action Group

## Test Procedure

The management lock was intentionally deleted outside Terraform to simulate an administrative change to a governance control.

The deletion was performed separately from the Terraform workflow so that the monitoring system and Terraform drift detection could observe the change.

## Expected Result

Azure should record the management lock deletion as an administrative event.

The configured Activity Log Alert should detect the operation and route the notification through the governance Action Group.

## Actual Result

The management lock deletion was recorded by Azure.

The monitoring configuration detected the governance change.

The deletion also caused the live Azure environment to differ from the Terraform-defined desired state.

## Result

**PASS**

The management lock monitoring control successfully provided visibility into removal of the resource protection control.

## Evidence

Screenshot:

`evidence/management-lock-deletion-monitoring.png`

---

# VAL-09 — Policy Assignment Tampering Detection

## Objective

Verify that the monitoring system detects deletion of an Azure Policy assignment.

## Control

**Policy Assignment:** `allowed-locations`

**Monitoring Alert:** `52logistics-policy_assignment_deleted`

**Operation Monitored:**

`Microsoft.Authorization/policyAssignments/delete`

**Category:** Administrative

## Test Procedure

While authenticated as the subscription Owner, the `allowed-locations` policy assignment was intentionally deleted outside Terraform.

This simulated a privileged administrator removing an organizational governance guardrail.

Terraform was not immediately executed after the deletion so that the monitoring and alerting systems could be validated before remediation.

## Expected Result

Azure Activity Log should record the policy assignment deletion.

The configured Activity Log Alert should detect the operation and trigger the governance Action Group.

## Actual Result

Azure Activity Log recorded:

`Microsoft.Authorization/policyAssignments/delete`

The event identified the deleted `allowed-locations` policy assignment and recorded the identity responsible for the operation.

The configured policy-assignment deletion alert was enabled and monitoring the subscription.

## Result

**PASS**

The monitoring system successfully detected deletion of an Azure governance control.

## Evidence

Screenshot:

`evidence/policy-assignment-deletion-detected.png`

---

# VAL-10 — Governance Email Notification

## Objective

Verify that detected governance changes generate an external notification to the governance administrator.

## Control

**Service:** Azure Monitor Action Group

**Trigger:** Policy assignment deletion Activity Log Alert

**Delivery Method:** Email

## Test Procedure

The `allowed-locations` policy assignment deletion performed during VAL-09 was allowed to trigger the configured Azure Monitor alert.

The governance administrator's email inbox was then checked for the notification generated by the Action Group.

## Expected Result

An Azure Monitor notification should be delivered containing information about the governance event.

## Actual Result

The Azure Monitor email notification was successfully received.

The notification identified information including:

- The Activity Log Alert
- The affected policy assignment
- The policy deletion operation
- The administrative category
- The identity associated with the operation
- The event timestamp

## Result

**PASS**

The Action Group successfully delivered an external notification when a governance control was deleted.

## Evidence

Screenshot:

`evidence/policy-deletion-email-alert.png`

---

# VAL-11 — Activity Log Attribution

## Objective

Verify that Azure records sufficient information to identify who performed a governance-changing operation.

## Test Procedure

After intentionally deleting the `allowed-locations` policy assignment, Azure Activity Log was queried using Azure CLI.

The query searched for successful policy assignment deletion operations.

## Expected Result

The Activity Log should contain the policy deletion event and identify the caller responsible for the operation.

## Actual Result

Azure returned the policy deletion event with:

**Operation:**

`Microsoft.Authorization/policyAssignments/delete`

**Caller:**

The authenticated governance administrator account used during the test.

**Resource:**

The `allowed-locations` policy assignment.

**Timestamp:**

The time of the administrative operation was recorded.

## Result

**PASS**

Azure provided an audit trail identifying what governance operation occurred, which resource was affected, when the operation occurred, and which identity performed it.

## Evidence

Screenshot:

`evidence/policy-deletion-activity-log.png`

---

# VAL-12 — Terraform Drift Detection

## Objective

Verify that Terraform detects when a Terraform-managed governance control is removed directly from Azure.

## Control

**Terraform Resource:**

`azurerm_subscription_policy_assignment.allowed_locations`

## Test Procedure

The `allowed-locations` policy assignment was deleted directly from Azure during the monitoring test.

No corresponding change was made to the Terraform configuration.

After monitoring evidence was collected, the following command was executed:

`terraform plan`

## Expected Result

Terraform should refresh the live Azure environment, compare it against the Terraform configuration and state, and identify that the policy assignment no longer exists.

Terraform should propose recreating the missing resource.

## Actual Result

Terraform reported:

`Objects have changed outside of Terraform`

Terraform identified that:

`azurerm_subscription_policy_assignment.allowed_locations`

had been deleted outside Terraform.

Terraform then proposed:

`Plan: 1 to add, 0 to change, 0 to destroy.`

## Result

**PASS**

Terraform successfully detected configuration drift caused by an out-of-band administrative change.

## Evidence

Screenshot:

`evidence/terraform-policy-drift-detected.png`

---

# VAL-13 — Terraform Drift Remediation

## Objective

Verify that Terraform can restore a governance control that was removed outside the Infrastructure as Code workflow.

## Test Procedure

After Terraform detected the missing `allowed-locations` policy assignment, the Terraform configuration was applied again.

The configuration still defined the policy assignment as part of the intended Azure governance baseline.

After remediation, another Terraform plan was performed to verify the final state.

## Expected Result

Terraform should recreate the missing policy assignment.

A subsequent Terraform plan should report that the deployed Azure environment matches the configuration.

## Actual Result

Terraform recreated the deleted `allowed-locations` policy assignment.

A final Terraform plan confirmed that no additional infrastructure changes were required.

The desired governance state was restored.

## Result

**PASS**

Terraform successfully remediated the out-of-band configuration drift and returned the environment to the intended governance baseline.

## Evidence

Screenshots:

`evidence/terraform-policy-remediation.png`

`evidence/terraform-final-no-drift.png`

---

# Governance Change Response Chain

VAL-09 through VAL-13 validated the complete response lifecycle:

Policy Guardrail Exists
        ↓
Privileged Administrator Deletes Guardrail
        ↓
Azure Activity Log Records Change
        ↓
Caller Is Identified
        ↓
Azure Monitor Detects Operation
        ↓
Action Group Sends Email Notification
        ↓
Terraform Detects Configuration Drift
        ↓
Terraform Proposes Remediation
        ↓
Policy Assignment Is Restored
        ↓
Final Terraform Plan Confirms Desired State

This test demonstrated that the environment provides more than preventative controls.

It also provides detection, accountability, notification, drift identification, and recovery when a governance control is changed outside the intended Infrastructure as Code workflow.

# VAL-14 — Automated Governance Baseline Audit

## Objective

Verify that the deployed Azure environment can be independently audited using PowerShell and Azure CLI.

The goal was to create a validation method that queries the live Azure environment instead of relying only on Terraform state or Terraform output.

## Control

**Script:**

`scripts/governance-audit.ps1`

**Data Source:**

Azure CLI queries against the live Azure subscription.

**Processing:**

PowerShell objects and conditional validation logic.

## Test Procedure

The PowerShell governance audit script was executed after the Terraform-managed environment had been restored to its intended state.

The script collected information about:

- Current Azure subscription
- Current authenticated identity
- Azure Policy assignments
- RBAC assignments
- RBAC scopes
- Management lock configuration
- Expected governance policy baseline

The script then compared the discovered governance configuration against the expected baseline.

## Expected Result

The audit should identify all required policy assignments and confirm that the expected `CanNotDelete` management lock exists.

If all required controls are detected, the script should return a healthy governance status.

## Actual Result

The audit successfully detected the required policies:

`required-tag : PASS`

`allowed-locations : PASS`

`Allowed virtual machine size SKUs : PASS`

The management lock validation returned:

`Management Lock: PASS`

The final policy result was:

`Policies Passed: 3 / 3`

The final environment status was:

`Governance Status: Healthy`

## Result

**PASS**

The PowerShell audit successfully queried the live Azure environment and validated the expected governance baseline.

## Evidence

Screenshot:

`evidence/governance-audit-healthy.png`

---

# VAL-15 — Governance Audit Failure Path

## Objective

Verify that the PowerShell governance audit does not automatically report a healthy environment when an expected governance control cannot be found.

## Test Procedure

During development, one of the expected policy names in the PowerShell baseline did not match the policy assignment present in Azure.

The script attempted to locate all three required governance policies.

Because one expected value could not be matched, the validation count decreased.

## Expected Result

The script should identify that the expected baseline is incomplete and change the final governance health status.

## Actual Result

The audit returned:

`Policies Passed: 2 / 3`

The management lock remained:

`Management Lock: PASS`

The final status changed to:

`Governance Status: ATTENTION REQUIRED`

After correcting the expected policy name and rerunning the audit, the result returned to:

`Policies Passed: 3 / 3`

`Governance Status: Healthy`

## Result

**PASS**

The audit health logic responded correctly when an expected governance control could not be located.

This test also helped validate that the final health status is calculated from the discovered environment rather than being a static success message.

## Evidence

Screenshots:

`evidence/governance-audit-attention-required.png`

`evidence/governance-audit-healthy.png`

---

# Final Validation Results

The V1 governance baseline successfully passed all planned validation scenarios.

| Validation Area | Tests Passed |
|---|---:|
| Azure Policy Enforcement | 3 / 3 |
| RBAC Enforcement | 2 / 2 |
| Management Lock Protection | 2 / 2 |
| Monitoring and Alerting | 4 / 4 |
| Terraform Drift Management | 2 / 2 |
| Automated Governance Audit | 2 / 2 |

**Total: 15 / 15**

**Final Status: PASS**

---

# Control Interaction Summary

The testing demonstrated that the governance controls operate as separate but complementary layers.

## RBAC

Determines whether an identity is authorized to perform an operation at a particular Azure scope.

Validated behavior:

- Reader at subscription could view resources but could not create a resource group.
- Contributor at `52logistics-rg` could deploy and manage resources within that scope.

## Azure Policy

Determines whether the requested resource configuration complies with the organization's deployment requirements.

Validated behavior:

- Unapproved region blocked.
- Missing required tag blocked.
- Unapproved VM SKU blocked.

## Management Locks

Provide additional protection against destructive operations.

Validated behavior:

- Contributor could manage the workload but could not delete a protected resource.
- Contributor could not remove the management lock protecting the environment.

## Azure Monitor

Provides visibility into administrative changes affecting governance controls.

Validated behavior:

- Governance changes were recorded.
- Policy assignment deletion was detected.
- Caller identity was recorded.
- Email notification was delivered.

## Terraform

Defines and maintains the desired governance state.

Validated behavior:

- Out-of-band deletion was detected.
- Missing governance control was proposed for recreation.
- Terraform restored the control.
- Final plan confirmed the desired state.

## PowerShell and Azure CLI

Provide an independent validation layer against the live Azure environment.

Validated behavior:

- Policy assignments retrieved.
- RBAC assignments and scopes retrieved.
- Management lock verified.
- Expected baseline evaluated.
- Final governance health calculated.

---

# Final Governance Lifecycle

The completed project validates the following operational lifecycle:

Deploy
    ↓
Terraform establishes the governance baseline.

Restrict
    ↓
RBAC limits access according to identity and scope.

Enforce
    ↓
Azure Policy restricts noncompliant deployments.

Protect
    ↓
Management locks prevent destructive operations.

Monitor
    ↓
Azure Activity Log records administrative changes.

Alert
    ↓
Azure Monitor and Action Groups notify administrators.

Audit
    ↓
PowerShell and Azure CLI inspect the live environment.

Detect Drift
    ↓
Terraform identifies changes made outside Infrastructure as Code.

Remediate
    ↓
Terraform restores the intended governance configuration.

Verify
    ↓
The PowerShell audit confirms the environment has returned to a healthy baseline.

---

# Evidence Index

The public `evidence/` directory should contain curated screenshots corresponding to the validation tests.

Recommended naming structure:

01-allowed-location-denied.png

02-required-tag-denied.png

03-vm-sku-policy-denied.png

04-rbac-subscription-create-denied.png

05-rbac-rg-deployment-success.png

06-management-lock-delete-blocked.png

07-contributor-lock-delete-denied.png

08-management-lock-monitoring.png

09-policy-assignment-deletion-detected.png

10-governance-email-alert.png

11-policy-deletion-activity-log.png

12-terraform-drift-detected.png

13-terraform-drift-remediation.png

14-terraform-final-no-drift.png

15-governance-audit-attention-required.png

16-governance-audit-healthy.png

The filenames can be adjusted to match the actual screenshots available in the repository.

Raw development and troubleshooting logs are intentionally excluded from the public repository.

---

# Validation Conclusion

The project successfully demonstrated that the Azure governance baseline could do more than deploy configuration.

The environment was intentionally tested against unauthorized operations, noncompliant deployments, destructive actions, privileged governance changes, and configuration drift.

The controls successfully demonstrated:

- Prevention
- Least-privilege authorization
- Policy enforcement
- Resource protection
- Administrative accountability
- Change detection
- Alerting
- Drift detection
- Remediation
- Independent validation

The final environment returned:

`Policies Passed: 3 / 3`

`Management Lock: PASS`

`Governance Status: Healthy`

**52 Logistics Azure Governance Guardrails V1 validation is complete.**