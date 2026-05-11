# OKX Skill Quality rubric → coach step mapping

The OKX Agentic Trading Contest Skill Quality Award is judged on five criteria. This file maps each rubric line to the coach steps that produce evidence for it.

> **Rubric (verbatim, from `competition_detail --activity-id 113`):**
> "Strategy completeness, risk control framework, execution reliability, user safety onboarding experience, and observability."

## 1. Strategy completeness

**Evidence produced by:** Step 3 (Strategy: pick or build) + the JSON spec at `schema.json`.

Every emitted spec has a non-empty `entry`, `exit`, `sizing`, and `risk` block. `additionalProperties: false` in the schema means we can't ship a malformed strategy. `oracle_grounding.rule_verdicts` is required and non-empty — no rule survives without a verdict.

**Reviewer can verify by:** running the coach in dry-run mode, asking for the spec at any step, validating against `schema.json` with any JSON Schema 2020-12 validator.

## 2. Risk control framework

**Evidence produced by:** Step 3 dissent-acknowledgement gate + the `risk` block + `circuit_breaker_on_dissent_strength`.

A rule with verdict `pass` cannot land in the spec without `acknowledged_by_user: true`. The risk block requires `max_concurrent_positions`, `max_single_position_pct`, `max_daily_loss_pct`. The circuit-breaker field halts entries when surviving dissent crosses a strength threshold — this is the investor-canon-grounded analogue of a market-state stop.

**Reviewer can verify by:** attempting to force a `pass`-verdict rule into a spec without acknowledgement → coach refuses.

## 3. Execution reliability

**Evidence produced by:** Step 6 (Go live) delegation to existing OKX / SendAI / Backpack skills, NOT direct transaction signing.

The coach NEVER calls `wallet send` or `wallet contract-call` directly. It emits the spec and the `execution_rail` field tells the orchestrating agent which skill to invoke (`okx-dex-swap`, `okx-dapp-discovery`, or external). Reliability inherits from the underlying skill — we don't re-implement order routing.

**Reviewer can verify by:** grepping the SKILL.md for `wallet send`, `contract-call`, `broadcast` — zero hits expected. The coach hands off, period.

## 4. User safety onboarding experience

**Evidence produced by:** Step 0 preflight + Step 1 onboarding + Step 5 paper-trade hard-gate.

- Step 0 verifies the user has Gecko MCP and (preferably) execution rails before any coaching begins.
- Step 1 sets cost expectations up front and surfaces spec-only mode if execution isn't wired.
- Step 5 is a **non-skippable** paper-trade gate. The coach refuses to advance to live without N candidate trades evaluated in `mode: paper`.

**Reviewer can verify by:** asking the coach to skip from Step 4 directly to Step 6 → coach refuses with a clear reason.

## 5. Observability

**Evidence produced by:** the `oracle_grounding` block + Step 6 audit-log integration.

Every rule in the emitted spec carries `verdict_id`, `citations[]`, and optional `dissent_id` — a full audit trail of *why* this strategy looks the way it does. Step 6 wires execution events into `onchainos audit-log` (or stderr fallback). Reviewers can reconstruct any decision the coach made by replaying verdict IDs through the Gecko verdict store.

**Reviewer can verify by:** taking any rule_verdict, calling `gecko-mcp` to fetch the verdict by id, and confirming citation chunk_ids resolve to real corpus entries.

## Anti-rubric — what we explicitly DO NOT optimize for

- **PnL leaderboard.** Not our track. Coach refuses to optimize for maximum PnL — that's a wrong-incentive trap that produces over-leveraged strategies.
- **Trade frequency.** Coach defaults to fewer, higher-conviction trades. A strategy that fires 100x per day is a Skill Quality red flag, not a green one.
- **Trade volume.** We don't pad the spec to hit a volume threshold. Min volume for Participation reward is the user's call, not the coach's.
