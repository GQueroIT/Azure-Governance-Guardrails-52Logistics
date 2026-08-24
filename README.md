# Azure Governance Guardrails – 52 Logistics

## Project Overview

52 Logistics needed a repeatable Azure governance baseline that could control how resources are deployed and managed across the environment.

The goal was not only to deploy governance controls, but to build a system that could answer several operational questions:

- Who is allowed to manage Azure resources?
- Where does that access apply?
- What resources are users allowed to deploy?
- How are critical resources protected from accidental deletion?
- What happens if someone removes a governance control?
- Can configuration drift be detected and corrected?
- Can the deployed governance baseline be independently validated?

I built the environment using Terraform and then tested the controls using Azure CLI and PowerShell rather than assuming a successful Terraform deployment meant the environment was working correctly.

The finished project combines Infrastructure as Code, Azure governance, monitoring, security controls, drift detection, and automated validation.

---

## Architecture

The governance system follows this lifecycle:

Terraform
    |
    v
Azure Governance Baseline
    |
    +-- RBAC
    +-- Azure Policy
    +-- Resource Locks
    +-- Cost Budget
    +-- Microsoft Defender for Cloud
    +-- Azure Monitor
    |
    v
Control Enforcement
    |
    v
Activity Log Monitoring
    |
    v
Governance Alerts
    |
    v
PowerShell Validation
    |
    v
Terraform Drift Detection / Remediation

This creates a governance lifecycle of:

**Deploy → Restrict → Protect → Monitor → Audit → Detect Drift → Remediate**

---

## Technologies Used

- Microsoft Azure
- Terraform
- Azure CLI
- PowerShell
- Azure RBAC
- Azure Policy
- Azure Resource Locks
- Azure Monitor
- Azure Activity Log
- Azure Action Groups
- Microsoft Defender for Cloud
- Azure Cost Management
- Git / GitHub

## Infrastructure as Code

The Azure governance baseline is deployed and managed using Terraform.

I separated the Terraform configuration by responsibility instead of building the entire environment inside one large file. This makes the configuration easier to navigate, troubleshoot, and modify as the environment grows.

Project structure:

- provider.tf
- variables.tf
- terraform.tfvars
- resource-group.tf
- rbac.tf
- policies.tf
- locks.tf
- budgets.tf
- defender.tf
- monitoring.tf
- outputs.tf

Environment-specific and sensitive Terraform files are excluded from the public repository through `.gitignore`, including Terraform state and variable files.

---

## RBAC Design

The project uses scoped Role-Based Access Control (RBAC) to separate visibility from resource management permissions.

A test identity was configured with:

| Principal | Role | Scope |
|---|---|---|
| Governance Administrator | Owner | Subscription |
| Test User | Reader | Subscription |
| Test User | Contributor | `52logistics-rg` |

This design allows the test user to view resources across the subscription while limiting their management permissions to the designated resource group.

### RBAC Validation

I did not rely only on the Terraform role assignments to determine whether RBAC was working. I authenticated to Azure as the restricted test user and attempted operations at different scopes.

**Test 1 – Subscription Scope**

The test user attempted to create a new resource group.

**Result: DENIED**

Azure returned:

`AuthorizationFailed`

The identity did not have authorization to perform:

`Microsoft.Resources/subscriptions/resourceGroups/write`

This demonstrated that the Reader assignment at subscription scope did not provide resource creation permissions.

**Test 2 – Resource Group Scope**

Using the same identity, I deployed a storage account inside `52logistics-rg`.

**Result: SUCCESS**

The Contributor assignment at the resource group scope allowed the deployment.

This demonstrated that the same identity could have different capabilities depending on the Azure scope where the operation was performed.

---

## Azure Policy Guardrails

Azure Policy is used to establish deployment boundaries for the environment.

The governance baseline includes policies for:

- Required resource tagging
- Allowed Azure regions
- Allowed virtual machine SKUs

These controls operate independently from RBAC.

A user may have permission through RBAC to create a resource while Azure Policy can still deny that deployment if it violates an organizational requirement.

### Policy Validation

Each major policy was deliberately tested using noncompliant deployments.

**Allowed Locations**

A resource deployment was attempted outside the approved Azure regions.

Approved regions:

- `eastus`
- `eastus2`

**Result: DENIED**

Azure returned `ResourceDisallowedByPolicy`.

**Required Tag**

A resource was deployed without the required `Environment = Production` tag.

**Result: DENIED**

Azure Policy identified the missing tag and blocked the deployment.

**Allowed VM SKUs**

The environment permitted:

- `Standard_B1s`
- `Standard_B2s`

A VM deployment was attempted using `Standard_D2s_v5`.

**Result: DENIED**

Azure Policy prevented the VM from being created because the requested SKU was outside the approved list.

## Resource Protection

A `CanNotDelete` management lock protects the primary `52logistics-rg` resource group.

The purpose of the lock is to provide another layer of protection against accidental or unauthorized deletion of resources.

### Management Lock Validation

I tested the lock using the restricted Contributor identity.

The test user had sufficient RBAC permissions to manage resources inside `52logistics-rg`, so I attempted to delete a storage account inside the protected resource group.

**Result: BLOCKED**

Azure returned:

`ScopeLocked`

This demonstrated an important difference between RBAC and management locks.

RBAC authorized the user to manage the resource, but the management lock still prevented the deletion.

I then attempted to remove the management lock while authenticated as the same Contributor.

**Result: DENIED**

Azure returned:

`AuthorizationFailed`

The Contributor did not have authorization to perform:

`Microsoft.Authorization/locks/delete`

This demonstrated that the workload operator could manage resources within the assigned scope without having the permissions necessary to remove the governance protection surrounding those resources.

---

## Monitoring and Accountability

Monitoring and accountability were important parts of the design.

I did not want the governance system to only prevent certain operations. I also wanted visibility into administrative changes that could weaken or remove the controls protecting the environment.

Azure Monitor Activity Log Alerts were deployed through Terraform to monitor important governance events.

The monitoring system watches for events including:

- Management lock deletion
- Azure Policy assignment deletion

Both alerts use an Azure Monitor Action Group to notify the governance administrator.

This provides visibility into:

- What operation occurred
- Which resource or governance control was affected
- When the operation occurred
- Which identity performed the action

---

## Governance Alert Validation

The monitoring system was tested by intentionally modifying governance controls outside Terraform.

### Management Lock Monitoring

The management lock was manually deleted from the Azure Portal.

Azure recorded the administrative operation and the monitoring configuration detected the change.

This also created configuration drift between Azure and the Terraform configuration.

Terraform later detected that the lock had been removed and recreated the expected resource.

**Result: PASS**

### Policy Assignment Monitoring

The `allowed-locations` policy assignment was intentionally deleted while authenticated as the subscription Owner.

Azure Activity Log recorded:

Operation:
`Microsoft.Authorization/policyAssignments/delete`

Category:
`Administrative`

The Activity Log also recorded the identity responsible for the operation.

The configured Azure Monitor Activity Log Alert detected the deletion and triggered the existing governance Action Group.

An email notification was successfully delivered to the governance administrator.

**Result: PASS**

This demonstrated that a privileged identity could intentionally change the environment, but the action would still leave an audit trail and generate an administrative notification.

---

## Terraform Drift Detection and Remediation

Deleting governance resources outside Terraform allowed me to test configuration drift.

After manually deleting the `allowed-locations` policy assignment, I ran:

`terraform plan`

Terraform refreshed the live Azure environment and reported:

`Objects have changed outside of Terraform`

Terraform identified that:

`azurerm_subscription_policy_assignment.allowed_locations`

had been deleted.

The resulting plan showed:

`Plan: 1 to add, 0 to change, 0 to destroy.`

This demonstrated that the real Azure environment no longer matched the desired state defined in Terraform.

I then ran Terraform again to recreate the missing policy assignment.

After remediation, a final `terraform plan` confirmed that the Azure environment once again matched the Terraform configuration.

This created a complete governance response workflow:

Governance Control Deployed
        ↓
Out-of-Band Change
        ↓
Azure Activity Log
        ↓
Azure Monitor Alert
        ↓
Administrator Notification
        ↓
Terraform Drift Detection
        ↓
Terraform Remediation
        ↓
Desired State Restored

---

## Automated Governance Audit

The final technical component of the project was a PowerShell governance audit script:

`scripts/governance-audit.ps1`

I created the script to provide an independent method of checking the live Azure environment after deployment.

Rather than relying only on Terraform state or Terraform outputs, the script uses Azure CLI commands to retrieve information directly from Azure and then processes the returned data with PowerShell.

The audit currently checks:

- Azure Policy assignments
- RBAC assignments
- RBAC scopes
- Management lock existence
- Management lock level
- Expected governance policy baseline
- Final governance health status

### Governance Baseline Validation

The script compares the policy assignments found in Azure against the controls that are expected to exist.

The required policy baseline includes:

- `required-tag`
- `allowed-locations`
- `Allowed virtual machine size SKUs`

It also verifies that the expected `CanNotDelete` management lock exists.

The final successful audit returned:

Policy Compliance Verification
------------------------------
required-tag : PASS
allowed-locations : PASS
Allowed virtual machine size SKUs : PASS

Governance Audit Summary
------------------------
Policies Passed: 3 / 3
Management Lock: PASS

Governance Status: Healthy

### Failure-Path Validation

While developing the audit script, I also verified that the health logic would respond when an expected control could not be found.

When one of the expected policy names did not match the live Azure environment, the script returned:

Policies Passed: 2 / 3
Management Lock: PASS

Governance Status: ATTENTION REQUIRED

After correcting the expected baseline, the audit returned to:

`Governance Status: Healthy`

This helped demonstrate that the script was not simply printing a predetermined successful result. The final health status depends on whether the expected governance controls are actually detected.

---

## Validation Strategy

I intentionally tested both successful and unsuccessful operations throughout the project.

| Control | Validation Test | Expected Result | Result |
|---|---|---|---|
| RBAC | Test user attempts resource group creation at subscription scope | Denied | PASS |
| RBAC | Test user deploys resource inside authorized resource group | Allowed | PASS |
| Azure Policy | Deploy resource outside approved regions | Denied | PASS |
| Azure Policy | Deploy resource without required tag | Denied | PASS |
| Azure Policy | Deploy VM using unapproved SKU | Denied | PASS |
| Resource Lock | Contributor attempts protected resource deletion | Blocked | PASS |
| Resource Lock | Contributor attempts to remove lock | Denied | PASS |
| Monitoring | Delete management lock | Event detected | PASS |
| Monitoring | Delete policy assignment | Alert generated | PASS |
| Activity Log | Identify identity responsible for policy deletion | Recorded | PASS |
| Action Group | Send governance notification | Email delivered | PASS |
| Terraform | Detect manually deleted governance control | Drift detected | PASS |
| Terraform | Restore deleted governance control | Restored | PASS |
| PowerShell | Validate expected governance baseline | Healthy | PASS |

The purpose of these tests was to verify actual behavior instead of treating a successful deployment as proof that the controls worked.

---

## Evidence

Curated validation evidence is stored in the `evidence/` directory.

The evidence documents important stages of the project, including:

- Terraform deployment and planning
- RBAC scope enforcement
- Successful scoped resource deployment
- Azure Policy denial messages
- Management lock enforcement
- Contributor authorization failures
- Azure Activity Log events
- Governance alert configuration
- Email alert delivery
- Terraform drift detection
- Terraform remediation
- PowerShell governance audit results

A more detailed explanation of the validation scenarios is maintained in:

`docs/validation-results.md`

The raw `validation-session.txt` used during development is intentionally excluded from the public repository.

That file contains the full working session, including troubleshooting commands, temporary testing information, raw Azure output, and environment-specific details.

The public repository contains curated evidence instead of the complete raw engineering session.

---

## Security and Repository Hygiene

The repository is designed to demonstrate the project without intentionally exposing unnecessary environment information.

Files and information excluded from the public repository include:

- Terraform state files
- Terraform state backups
- `terraform.tfvars`
- Authentication credentials
- Secrets
- Raw validation session logs
- Temporary Terraform files
- Environment-specific information that is not required to understand the project

`.gitignore` is used to prevent Terraform state, local variable files, and other local artifacts from being committed.

No credentials or secrets should be stored directly inside the Terraform configuration or PowerShell validation script.

---

## Key Lessons

This project changed the way I think about Azure governance and Infrastructure as Code.

When I started working with these services, RBAC, Azure Policy, resource locks, monitoring, and Terraform felt like separate topics. Building and testing the environment helped me understand how they can operate together as different layers of the same system.

---

### Terraform

Terraform became easier to understand as I worked through the project.

I like being able to separate the configuration into files based on responsibility because it creates a logical flow through the environment. If I need to modify RBAC, monitoring, policies, budgets, or locks, I know exactly where that configuration is located.

Using variables and `terraform.tfvars` also helped me understand how the same configuration can become more reusable instead of hardcoding environment-specific values throughout the project.

One of the most important lessons was that Terraform still has to operate within the governance controls protecting the environment. Resource locks affected some of the changes I wanted Terraform to perform, which forced me to think about the lifecycle of protected infrastructure instead of only the deployment.

### RBAC, Policy, Locks, and Scope

Understanding Azure scope was one of the biggest improvements I made during this project.

I now understand the hierarchy:

Management Group
    ↓
Subscription
    ↓
Resource Group
    ↓
Resource

I also have a much clearer understanding of the different questions each governance control answers.

RBAC:
Who is authorized to perform the operation?

Azure Policy:
Is the requested resource or configuration allowed?

Resource Locks:
Can a protected resource be modified or deleted?

Testing these controls together helped me understand that having permission through one control does not automatically bypass another.

The clearest example was the Contributor test identity.

The user had permission to manage resources inside `52logistics-rg`, but:

- Could not create a resource group at subscription scope
- Could not deploy resources that violated Azure Policy
- Could not delete resources protected by the management lock
- Could not remove the management lock itself

That made scoped governance much easier for me to understand than studying each service separately.

### PowerShell and Azure CLI

Building the PowerShell audit script gave me more experience working with live Azure data instead of only deploying infrastructure.

I learned how to:

- Query Azure using Azure CLI
- Convert JSON responses into PowerShell objects
- Store returned information in variables
- Inspect object properties
- Loop through returned resources
- Compare expected and actual values
- Work with `$null`
- Use conditional logic
- Build PASS/FAIL validation checks

I also learned how small naming mistakes can affect automation.

During development, I had to troubleshoot incorrect PowerShell property names and a resource group naming mismatch that caused a management lock check to incorrectly report a failure.

Working through those problems helped me understand the importance of inspecting the actual data returned by a command instead of assuming the structure of the object.

I still need more repetition with PowerShell and Azure CLI before the commands become automatic, but this project gave me a practical reason to use them.

### Monitoring

Monitoring became an important part of the project because prevention by itself does not provide complete visibility.

A privileged administrator may legitimately have enough access to remove a governance control.

The important question then becomes:

What happens when they do?

By monitoring administrative operations, I was able to create accountability around changes to the governance environment.

The policy deletion test demonstrated that Azure could record:

- What happened
- What resource was affected
- Who performed the operation
- When the operation occurred

Azure Monitor could then generate an alert and notify the administrator.

That changed the project from only enforcing controls to also providing visibility when those controls are changed.

---

## What This Project Demonstrates

This project demonstrates practical experience with:

- Infrastructure as Code
- Azure governance architecture
- Least-privilege access
- Azure scope and inheritance
- Policy-based deployment guardrails
- Resource protection
- Cost governance
- Cloud security configuration
- Activity Log monitoring
- Administrative change detection
- Alerting and notification
- Infrastructure validation
- Configuration drift detection
- Drift remediation
- PowerShell automation
- Azure CLI
- Troubleshooting
- Failure-path testing

More importantly, the project demonstrates the ability to build a control and then verify that the control actually works.

---

## Engineering Workflow

The final system follows this workflow:

Deploy
  ↓
Terraform establishes the Azure governance baseline.

Restrict
  ↓
RBAC limits user capabilities according to scope.

Enforce
  ↓
Azure Policy prevents deployments that violate organizational requirements.

Protect
  ↓
Management locks protect critical resources from deletion.

Monitor
  ↓
Azure Activity Log and Azure Monitor detect important administrative changes.

Alert
  ↓
Action Groups notify administrators when governance controls are modified.

Audit
  ↓
PowerShell and Azure CLI independently inspect the live Azure environment.

Detect Drift
  ↓
Terraform compares the deployed environment against the desired configuration.

Remediate
  ↓
Terraform restores missing or altered infrastructure.

Verify
  ↓
The governance audit confirms that the expected baseline is healthy.

---

## Project Status

### V1 — Complete

- [x] Terraform provider configuration
- [x] Resource group architecture
- [x] Terraform variables and outputs
- [x] Scoped RBAC
- [x] Required tag policy
- [x] Allowed locations policy
- [x] Allowed VM SKU policy
- [x] Management lock
- [x] Azure Cost Management budget
- [x] Microsoft Defender for Cloud configuration
- [x] Azure Monitor Action Group
- [x] Management lock deletion monitoring
- [x] Policy assignment deletion monitoring
- [x] Email alerting
- [x] RBAC positive-path testing
- [x] RBAC negative-path testing
- [x] Azure Policy enforcement testing
- [x] Management lock enforcement testing
- [x] Governance tampering simulation
- [x] Activity Log validation
- [x] Terraform drift detection
- [x] Terraform drift remediation
- [x] PowerShell governance audit
- [x] Governance health reporting

---

## Final Takeaway

The biggest lesson I am taking from this project is that deploying infrastructure is not enough.

I want to know:

- Who can access it?
- What are they allowed to change?
- What prevents them from operating outside the intended boundaries?
- What protects important resources?
- What happens when a governance control is removed?
- Can I identify who changed it?
- Will someone be notified?
- Can I detect when the environment no longer matches the design?
- Can I restore it?
- Can I independently prove that the environment is healthy?

This project allowed me to work through that entire lifecycle.

**Deploy → Restrict → Enforce → Protect → Monitor → Alert → Audit → Detect Drift → Remediate → Verify**

That is the approach I want to continue applying as I build larger Azure environments.