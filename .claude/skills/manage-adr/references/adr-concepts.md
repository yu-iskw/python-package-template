# Architecture Decision Records (ADRs)

An Architecture Decision Record (ADR) is a short text file that captures an important architectural decision made along with its context and consequences.

## Why use ADRs?

- **Historical Context**: Understand _why_ a decision was made months or years later.
- **Onboarding**: Help new team members understand the architectural evolution.
- **Alignment**: Ensure everyone is on the same page regarding technical choices.
- **Steerable memory**: Keep Accepted decisions binding for agents, while still allowing a better approach via Proposed supersession when Context changes.

## ADR Structure (Nygard Format)

1. **Title**: Number and short noun phrase (e.g., "1. Record architecture decisions").
2. **Status**: Proposed, Accepted, Superseded, Deprecated, or Rejected.
3. **Context**: The situation and the problem being solved.
4. **Decision**: The chosen solution.
5. **Consequences**: The results of the decision (good and bad).

## Status meanings (for coding agents)

| Status         | Meaning                                                                                                      |
| -------------- | ------------------------------------------------------------------------------------------------------------ |
| **Proposed**   | Under discussion. Not binding. Do not implement unless the user explicitly asked to change architecture now. |
| **Accepted**   | Binding for implementation.                                                                                  |
| **Superseded** | History. Replaced by a later ADR. Do not treat as a constraint.                                              |
| **Deprecated** | History. No longer applies; no replacement.                                                                  |
| **Rejected**   | History. Do not revive without new evidence.                                                                 |

## Re-litigation rule (Nygard)

Do **not** re-litigate an Accepted decision **without new Context**.

Do **reopen** a decision when Context changed: open a new ADR as **Proposed**, cite the evidence, and wait for Accept. That is supersession — not editing the old Decision in place.

Illegal:

- Editing Context / Decision / Consequences of an Accepted ADR.
- Changing Accepted → Proposed in place.
- Using `adr new -s` while the replacement is still Proposed (adr-tools immediately unbinds the old ADR).

## Managing Lifecycle

- **Challenge**: Create a Proposed ADR that may note “Proposes to supersede N” without calling `adr new -s`.
- **Accept**: Human gate. Set Status to Accepted, then apply Supercedes links (same effect as adr-tools `-s`).
- **Reject**: Mark Proposed as Rejected; leave old Accepted records unchanged.
- **Linking**: Related decisions should be linked (e.g., "Amends", "Depends on").

## Tools

We use `adr-tools` for numbering, `adr list`, and `adr generate toc`.

**adr-tools quirk:** `adr new` always writes Status **Accepted** (STATUS token substitution). The project wrapper rewrites new records to **Proposed**. Do not pass `-s` at create time; apply supersession only on Accept.
