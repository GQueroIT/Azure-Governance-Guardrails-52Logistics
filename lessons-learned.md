# Lessons Learned

This project became much more than a Terraform deployment for me. I started it as a way to practice Azure governance, but building and testing the environment helped me understand how Terraform, Azure RBAC, Azure Policy, resource locks, monitoring, Azure CLI, and PowerShell can work together as one system.

A major part of the learning came from deliberately testing the controls after I deployed them. I did not want the project to end with Terraform reporting that resources had been created successfully. I wanted to prove that the controls actually behaved the way I expected them to.

---

## Terraform

Terraform was easier for me to understand than I originally expected. I like the structure of the language because I can look at a resource block and usually identify exactly what I am trying to build.

Separating the configuration into files such as:

- `provider.tf`
- `resource-group.tf`
- `rbac.tf`
- `policies.tf`
- `locks.tf`
- `budgets.tf`
- `monitoring.tf`
- `defender.tf`
- `variables.tf`
- `outputs.tf`

made the project much easier for me to navigate.

Instead of having one large configuration, I could mentally separate the environment into different responsibilities. If I needed to work on RBAC, I knew where to go. If I needed to change monitoring, I could work inside the monitoring configuration without searching through everything else.

I also became more comfortable using variables and `terraform.tfvars`. I like being able to separate values that I may want to change from the actual resource configuration. It makes the Terraform configuration feel reusable instead of being written for only one deployment.

One of my favorite things about Terraform is how practical the language feels. I am describing the state that I want Azure to have, and Terraform determines what needs to happen to reach that state.

### Terraform State and Resource Locks

Resource locks taught me an important lesson about the difference between infrastructure configuration and the controls protecting that infrastructure.

The `CanNotDelete` lock worked exactly as intended, but that also created an interesting problem when Terraform needed to make changes involving protected resources.

During testing, I had to temporarily remove the lock configuration and its related output from the Terraform configuration, apply the required changes, and then add the lock configuration back and apply Terraform again.

At first this felt annoying, but it helped me understand something important: governance controls can also affect administrators and automation.

A control that prevents accidental deletion does not stop being a control just because Terraform is performing the operation.

That changed the way I look at infrastructure automation. Terraform may manage the environment, but it still has to operate within the controls that exist in Azure.

---

## RBAC, Azure Policy, and Resource Locks

RBAC, Azure Policy, resource locks, and Azure scopes were some of the more confusing parts of Azure governance for me in the beginning.

Individually, I understood what each service was supposed to do. What was harder was understanding how they work together and how their behavior changes depending on where they are assigned.

Building this environment helped that finally click.

I now think about Azure governance through scope:

Management Group
    ↓
Subscription
    ↓
Resource Group
    ↓
Resource

A control applied higher in the hierarchy can affect resources underneath it.

I also understand that RBAC, Policy, and locks solve different problems.

**RBAC answers:** Who is allowed to perform an action?

**Azure Policy answers:** Is the resource or configuration allowed to exist?

**Resource locks answer:** Can this resource be modified or deleted regardless of the user's normal resource permissions?

The RBAC testing was especially useful.

I configured a test user with:

- Reader at the subscription
- Contributor at the `52logistics-rg` resource group

I then tested those permissions instead of assuming the assignments worked.

The user could manage resources within the permitted resource group but could not create a new resource group at the subscription scope.

That test helped me understand scoped access much more clearly than simply reading about RBAC inheritance.

---

## Azure Policy

I used Azure Policy to establish guardrails around the environment, including controls for:

- Required tagging
- Allowed Azure regions
- Allowed virtual machine SKUs

The important lesson for me was that governance does not necessarily mean preventing users from doing their jobs.

The goal is to define the boundaries within which they are allowed to operate.

For example, a Contributor may have permission through RBAC to deploy a resource, but Azure Policy can still prevent that deployment if the resource violates an organizational requirement.

That distinction between **authorization** and **governance enforcement** became much clearer while testing this project.

---

## PowerShell, Azure CLI, and Validation

PowerShell was one of the areas where I learned the most through troubleshooting.

I am still developing my scripting skills, but creating `governance-audit.ps1` helped me understand how to retrieve Azure information, store returned objects in variables, inspect object properties, and use conditional logic to determine whether an expected control exists.

For example, I worked with logic such as:

`$null -ne $expectedLock`

Before building this script, syntax like this was something I could read without completely understanding how I would use it.

Now I understand the purpose.

I am asking:

> Did my query actually return the object that I expected?

I also learned how important property names are when working with returned objects.

During development, some of my RBAC output was blank because the properties I was referencing in PowerShell did not match the names of the properties returned by my Azure CLI query.

Instead of abandoning the script, I inspected the returned object and corrected the properties being referenced.

I ran into a similar problem while validating the management lock. The script reported:

`Status: FAIL`

even though I knew the lock existed.

I eventually discovered that the resource group name inside the script used an underscore instead of the hyphen used by the actual Azure resource group.

These were small mistakes, but troubleshooting them helped me understand how data moves from Azure CLI into PowerShell and how PowerShell evaluates the returned objects.

I also became more comfortable using Azure CLI commands to independently verify my Terraform deployment.

This is something I need to continue practicing. I still have to look up some commands and query syntax, but I am becoming much more comfortable figuring out how to retrieve the information I need.

My goal is to continue using Azure CLI and PowerShell in future projects until querying and validating Azure environments becomes much faster and more natural.

---

## Monitoring and Accountability

Monitoring was something I specifically wanted to add to this project.

I did not want governance to mean only blocking an action.

If someone changes an important control, I also want visibility into:

- What happened?
- What was changed?
- Who performed the action?
- When did it happen?
- What part of the environment was affected?

I used Terraform to deploy Azure Monitor components and activity log alerts for important governance events.

One of the most useful tests was intentionally deleting the `allowed-locations` Azure Policy assignment.

Azure recorded the deletion in the Activity Log, including the caller responsible for the operation, and the Azure Monitor alert generated an email notification.

This showed me the difference between simply enforcing governance and creating accountability around governance.

A control can fail, be changed, or even be intentionally removed. Monitoring provides visibility when that happens.

What I found especially interesting was that I created the monitoring configuration through Terraform and could then use Azure CLI and PowerShell to verify pieces of that environment independently.

---

## Terraform Drift

One of my favorite tests in the project involved intentionally creating configuration drift.

I manually deleted the `allowed-locations` policy assignment outside Terraform.

When I ran:

`terraform plan`

Terraform detected that the real Azure environment no longer matched the configuration.

It identified the missing policy assignment and proposed recreating it.

After running Terraform again, the policy was restored.

This gave me a much better understanding of what Terraform state actually means.

Terraform is not valuable only because it can create infrastructure. It also gives me a defined desired state that I can compare against the real environment.

The workflow became:

Terraform Configuration
        ↓
Azure Environment
        ↓
Manual / Unauthorized Change
        ↓
Azure Monitor Detection
        ↓
Terraform Drift Detection
        ↓
Remediation

That was one of the points where the different parts of the project started feeling like one system instead of separate Azure services.

---

## Automated Governance Audit

The final technical component was the PowerShell governance audit.

Instead of only listing Azure resources, I wanted the script to compare the live environment against an expected governance baseline.

The script currently verifies:

- Azure Policy assignments
- RBAC assignments and scopes
- Management lock existence and level
- Expected governance policies

The final validation returned:

`Policies Passed: 3 / 3`

`Management Lock: PASS`

`Governance Status: Healthy`

We also accidentally tested the failure path while developing it.

A policy name inside the expected baseline was incorrect, causing the audit to report:

`Policies Passed: 2 / 3`

`Governance Status: ATTENTION REQUIRED`

Although the failure came from my script rather than an Azure control being missing, it demonstrated that the health logic behaved correctly when an expected governance control could not be found.

---

## What This Project Changed for Me

The biggest thing I learned from this project is that deploying infrastructure is only one part of cloud engineering.

I need to think about what happens after the deployment.

Who can change it?

What are they allowed to deploy?

What prevents accidental deletion?

How do I know when an important control changes?

How do I prove that the environment still matches what I designed?

How can I restore the expected configuration when it does not?

This project started with Terraform resources and eventually became a small governance lifecycle:

**Deploy → Restrict → Protect → Monitor → Audit → Detect Drift → Remediate**

That is the part of the project I want to carry into future builds.

I do not want my projects to stop at "deployment successful."

I want to be able to prove that the system works.