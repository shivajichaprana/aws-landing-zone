# Design Decisions

This document records key architecture decisions made in this project, the reasoning behind them, and trade-offs considered.

## ADR-001: Terraform over AWS Control Tower

**Status:** Accepted

**Context:** AWS Control Tower provides a managed landing zone experience with guardrails, account factory, and a dashboard. However, several limitations make it unsuitable for teams that need full control over their multi-account strategy.

**Decision:** Use Terraform modules to build the landing zone from scratch using AWS Organizations, SCPs, IAM Identity Center, and CloudTrail directly.

**Rationale:**

- Control Tower is opaque — it creates resources behind the scenes that are difficult to inspect, modify, or debug. When something breaks, you're troubleshooting a black box.
- Control Tower guardrails are a mix of SCPs and AWS Config rules with limited customization. Our SCP module provides full control over policy content, attachment targets, and conditional enablement.
- Control Tower's Account Factory (AFT) requires a separate Terraform pipeline and has its own learning curve. Our account-vending module is a single Terraform resource with clear inputs.
- Control Tower manages its own OU structure and doesn't support arbitrary OU hierarchies well. Our Organizations module lets you define any OU layout.
- Terraform state gives us a single source of truth. Control Tower state is split across multiple AWS services with no unified view.

**Trade-offs:**

- We lose the Control Tower dashboard (mitigated by CloudWatch dashboards and Terraform outputs)
- We must implement our own drift detection (the terraform-drift-detector project addresses this)
- No automatic guardrail updates when AWS releases new best practices (we review and add manually)

## ADR-002: SCP Attachment Strategy — Per-OU, Not Per-Account

**Status:** Accepted

**Context:** SCPs can be attached to individual accounts or to OUs. Both approaches have trade-offs.

**Decision:** Attach all SCPs at the OU level, never at individual accounts.

**Rationale:**

- OU-level attachment provides inheritance — new accounts placed in an OU automatically receive all its SCPs without additional Terraform changes.
- Per-account SCPs create a maintenance burden that scales linearly with account count. OU-level scales with organizational structure, which changes rarely.
- OU-level makes it easy to reason about what policies apply where — look at the OU, not at each account.
- The `exclude_ous_from_region_restriction` variable allows surgical exceptions (e.g., Security OU needs global access for CloudTrail, IAM) without breaking the OU-level model.

**Trade-offs:**

- Less granularity — you can't apply an SCP to one account in an OU without affecting siblings. Mitigation: create a sub-OU for accounts that need different policies.
- Moving an account between OUs changes its SCP set. This is actually a feature — OU placement is the single mechanism for policy assignment.

## ADR-003: KMS Encryption for All Logging

**Status:** Accepted

**Context:** CloudTrail logs contain sensitive API activity. S3 server-side encryption (SSE-S3) provides encryption at rest, but doesn't offer key management, rotation, or audit trails.

**Decision:** Use a dedicated KMS Customer Managed Key (CMK) for CloudTrail log encryption in both S3 and CloudWatch Logs.

**Rationale:**

- CMK provides an auditable key usage trail via CloudTrail (who decrypted what, when)
- Automatic annual key rotation enabled by default
- Key policy restricts access to CloudTrail service and the management account — member accounts cannot decrypt logs directly
- Required for several compliance frameworks (SOC 2, HIPAA, PCI-DSS) that mandate customer-managed encryption keys
- The KMS key deletion window (default 30 days) prevents accidental data loss

**Trade-offs:**

- KMS API calls add minor cost (~$0.03 per 10,000 requests)
- Key policy must be carefully maintained — an overly restrictive policy can lock out legitimate access
- Cross-region disaster recovery requires key replication (not yet implemented)

## ADR-004: Modular Architecture with Explicit Dependencies

**Status:** Accepted

**Context:** The landing zone could be implemented as a single monolithic Terraform configuration or as separate, composable modules.

**Decision:** Split into 5 independent modules with explicit input/output contracts and `depends_on` declarations in the example.

**Rationale:**

- Each module can be developed, tested, and versioned independently
- Teams can adopt modules incrementally — start with Organizations + SCP, add SSO later
- Module boundaries enforce separation of concerns and prevent circular dependencies
- Terraform native tests can validate each module in isolation with mock providers
- Easier to reason about blast radius — a change to the SCP module doesn't require re-planning the entire landing zone

**Trade-offs:**

- More boilerplate (each module needs versions.tf, variables.tf, outputs.tf)
- Cross-module references require explicit variable passing (no implicit data source sharing)
- The complete example is more verbose than a monolithic config

## ADR-005: Conditional SCP Enablement

**Status:** Accepted

**Context:** Not all organizations need all guardrails from the outset. Forcing all SCPs on immediately can break existing workflows.

**Decision:** Each SCP has an `enable_*` boolean variable (defaulting to `true`) that controls whether the policy is created and attached.

**Rationale:**

- Allows gradual rollout — enable SCPs one at a time, monitor for breakage, then enable the next
- Makes it easy to temporarily disable a policy during an incident without destroying the resource
- The `count` meta-argument ensures disabled policies don't appear in state at all (no phantom resources)
- Default `true` means new deployments get full protection out of the box

**Trade-offs:**

- More variables to manage
- Risk of accidentally disabling a critical guardrail by setting a variable to `false`

## ADR-006: Organization-wide CloudTrail (Not Per-Account)

**Status:** Accepted

**Context:** CloudTrail can be configured per-account or as an organization trail that captures events from all accounts.

**Decision:** Use a single organization trail in the management account.

**Rationale:**

- One trail captures all API activity across all accounts — no gaps, no per-account setup
- Logs are delivered to a centralized S3 bucket in the Security OU, away from workload accounts
- Member accounts cannot disable or modify the organization trail
- Cost-effective — one trail instead of N trails (CloudTrail charges per trail per region)
- CloudWatch integration enables real-time alerting on security events across the entire organization

**Trade-offs:**

- All logs in one bucket creates a high-value target (mitigated by KMS encryption and bucket policy)
- Log volume can be large for big organizations (mitigated by lifecycle rules: Glacier at 365 days, delete at 455 days)
- S3 data events are disabled by default due to cost — must be explicitly enabled via variable
