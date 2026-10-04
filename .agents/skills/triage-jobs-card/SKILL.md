---
name: triage-jobs-card
description: Investigate production job issues in Code Moto-based applications and report deduplicated actionable findings on Linear cards when requested.
---

# Triage Jobs Card

1. Use this repository’s own read-only job diagnostics and inspect its job schema and code to investigate failed and blocked production jobs from the last 24 hours. Do not assume another application's tables or job states exist. Do not fix code or mutate production during triage.
2. Group failures by cause and affected job or domain. Include occurrence counts, latest occurrence, representative errors, and evidence from relevant recent commits and deployed changes. Distinguish ongoing issues, possibly fixed issues needing monitoring, and expected or unaddressable conditions.
3. For each actually addressable issue, search the configured Linear team's existing cards using Mr. Moto’s Linear task. Reuse a matching card and comment only when new information adds value. Otherwise request a card for user evaluation under the supplied Mr. Moto workflow, with a clear problem description and supporting evidence. Do not create cards for expected conditions or issues that cannot be addressed.
4. Comment on the triage tracking card with the complete list of findings, including conditions without cards and the identifiers of all created or reused cards.

Report whether investigation and reporting cover the requested scope. If required production data or tools are unavailable, record the blocker. Card outcomes follow the supplied Mr. Moto workflow.
