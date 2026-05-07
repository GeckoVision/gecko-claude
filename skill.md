---
name: gecko
description: Bootstrap a Gecko-powered project in Claude Code. Installs gecko-mcp, connects the user's frames.ag wallet via email + OTP (no browser), prompts funding, and runs a first paid research call. No API keys, no signup beyond the wallet. 19 tools — research, validation, planning, scaffolding, memory — paid per call via x402 on Solana.
---

# Gecko — Builder Bootstrap Platform

> **Wedge:** Gecko produces grounded, adversarial verdicts on pre-ideas — a judgment you can buy, sell, or stake on. Pre-loaded vertical knowledge bases (neobank, DEX, marketplace) served to your AI agent at every build step.

When a user pastes "Read https://app.geckovision.tech/skill.md and follow the instructions" into Claude Code, you (Claude) walk them through the four steps below. Every cent of payment runs on x402 over Solana via the user's frames.ag wallet.

## What you're installing

One MCP server (`gecko-mcp`) exposing **19 tools** across research, validation, planning, scaffolding, memory, and economics. Plus a skills registry, 5 sub-agents (`research-analyst`, `market-validator`, `technical-architect`, `validator`, `builder`), and helper skills wrapping the tools + `extract-page` (paid Tavily) + `fund-wallet`.

### Tool surface (19)

**Paid (x402):**

| Tool | Price | Purpose |
|---|---|---|
| `gecko_research` (basic) | **$20.00** | Discover sources → index → generate business plan + validation + PRD with citations |
| `gecko_research` (pro) | **$0.75** | Same as basic + 5-voice adversarial debate (analyst, critic, architect, scoper, judge) + market_landscape + surviving_dissent + dated falsifiers |
| `gecko_classify` | $0.10 | Classify an idea into Gecko's taxonomy + return a suggested-source list with priority weights |
| `gecko_plan` | $0.25 | Run the 5-voice Advisor Panel against an existing session — sprint plan with surviving dissent |
| `gecko_advise` | $0.05 | Run a single advisor voice (CEO / CTO / business_manager / product_manager / staff_manager) — 1 LLM call |
| `gecko_route` (default) | $0.01 | Route an LLM call through Gecko's cost-aware router (extraction/summary/default task_hint) |
| `gecko_route` (premium) | $0.05 | Premium tier — reasoning/code task_hint |
| `gecko_route` (upgrade) | $0.20 | Upgrade tier — `prefer_premium=True` |
| `gecko_review` (live) | $0.10 | Sprint review meta-tool — git log + memory + sprint docs → shipped[]/weakest_link/proposed_next[] |
| `gecko_scaffold` | $0.05 | Generate PRD.md + business-plan.md + BUILDING.md from a completed Pro debate |
| `gecko_report` | $0.05 | Generate a formatted HTML or markdown report for a completed session |
| `gecko_ask` | $0.01 (post-quota) | Follow-up question grounded in a session's chunks. First N calls per session FREE (default 100). |

**Free:**

| Tool | Purpose |
|---|---|
| `gecko_sources` | List indexed sources for the session (URL, type, chunk count, indexed_at) |
| `gecko_precedents` | Look up prior Gecko verdicts on similar ideas — top-K precedent rows with verdict + key_comparables |
| `gecko_available_sources` | Catalog of signal sources Gecko queries (Tavily, paysh_manifest, paysh_live, bazaar_manifest, bazaar_live, HN, Reddit, twit.sh, gecko_precedent flywheel, …) |
| `gecko_pulse` | Re-run advisor panel with fresh context — surface what changed since the last advise |
| `gecko_memory_save` | Append a typed entry to the decision-memory layer. Scope: `project | session | user` |
| `gecko_memory_recall` | Recall recent memory entries for a scope, newest first |
| `gecko_memory_search` | Cosine-similarity search over a scope's memory entries |
| `gecko_memory_query` | Structured filters (scope, entry_type, since, k) — falls back to cosine when `query` set |
| `gecko_resume` | Recap a project's recent loop activity — last advisor panel + last pulse deltas |
| `gecko_project_economics` | Per-project: privy wallet address, USDC balance, budget cap + spend, recent paid sessions |

## Step 1 — Run the installer

```bash
curl -fsSL https://app.geckovision.tech/install.sh | bash
```

Claude: confirm with the user before running. Installer is idempotent. Verifies Python 3.11+, installs `uv` if missing, runs `uv tool install gecko-mcp`, copies `.claude/` + `CLAUDE.md` + `.mcp.json` into the current directory, registers `gecko` with Claude Code via `claude mcp add`.

## Step 2 — Connect the user's frames.ag wallet (inside Claude Code, no browser)

**First check `~/.agentwallet/config.json`.** If it exists with `apiToken`, the user is already connected — skip to Step 3 with "Already connected as @<username>."

Otherwise:

1. Ask the user for their email.
2. `POST https://frames.ag/api/connect/start` with `{"email": "<email>"}` → returns `{username, ...}`. Save `username` for the next call.
3. Tell the user: "I sent a 6-digit code to <email>. Paste it back here." Wait for OTP.
4. `POST https://frames.ag/api/connect/complete` with `{"username": "<u>", "email": "<email>", "otp": "<6 digits>"}` → returns `{apiToken, evmAddress, solanaAddress, ...}`.
5. Save to `~/.agentwallet/config.json` with `chmod 600`. **Never echo the apiToken.** Confirm to the user with username + Solana address only.
6. On error: bad OTP → frames returns 401, ask the user to try again; expired OTP → frames returns 400, restart from step 1; frames 5xx → tell the user frames is having issues, retry in a minute.

## Step 3 — Fund the wallet

Print: `https://frames.ag/u/<username>` and tell the user "Open this in your browser to fund your wallet via Coinbase Onramp (PIX in Brazil, card/bank elsewhere). $5 USDC covers ~6 pro research sessions or ~50 advisor plans. Come back here when funded."

Optionally invoke the `fund-wallet` skill for full instructions on funding alternatives.

After they confirm funding: `gecko-mcp wallet balance` to verify. Don't proceed to Step 4 until balance > the session price they're about to invoke.

## Step 4 — First research

Suggest:

```
Use gecko_research to validate: <their idea, prompt if they don't have one>
```

Quote the price up-front. Default tier is `basic` ($20). For the demo or a price-sensitive user, suggest `tier="pro"` ($0.75) — surprisingly cheaper because pro is currently demo-priced to drive adoption of the 5-voice debate.

On approval, the MCP tool fires; payment settles in 5-10s; the workflow runs ~60s; full ResearchResult lands in your context (business_plan, validation_report, prd, sources, session_id, x402_tx_signature).

After the result lands, show:
- `gecko-mcp economics <session_id>` — cost/margin breakdown with the on-chain tx.
- Solana Explorer URL for the tx signature.

Hand off to the `research-analyst` sub-agent for exploration, or the `market-validator` if the user wants to stress-test the validation report. For a deeper sprint plan, suggest `gecko_plan` ($0.25). For a shareable artifact, suggest `gecko_report` ($0.05) → returns standalone HTML.

## A 60-second demo flow

If the user wants a quick end-to-end taste, run this exact sequence:

```
gecko_classify({ idea: "<their idea>" })                              # $0.10 — taxonomy + source list
gecko_research({ idea: "<their idea>", tier: "pro",                   # $0.75 — full 5-voice debate
                 tier_preset: "balanced" })
gecko_ask({ session_id: "<from above>",
            question: "Who are the top 3 competitors?" })             # $0.01 (or free under quota)
gecko_plan({ session_id: "<same>", tier_preset: "balanced" })         # $0.25 — sprint plan
gecko_report({ session_id: "<same>", format: "html" })                # $0.05 — shareable artifact
```

Total: **~$1.16 USDC** in ~5 minutes. The `gecko_report` HTML is the artifact you share with partners or paste into a Colosseum / Stellar37 application.

## Notes for Claude Code

- The frames.ag apiToken (`mf_...`) is the user's only credential. **Never log, echo, or paste it into conversation, errors, or commit messages.** Treat like a password.
- The `~/.agentwallet/config.json` file is `chmod 600` and gitignored. Never commit.
- Surface frames.ag errors verbatim: `POLICY_DENIED`, `WALLET_FROZEN`, `insufficient_funds`, `PAYMENT_REJECTED`. Don't paraphrase. Each has a short remediation in `CLAUDE.md`.
- First-time users almost always need Step 3. Don't skip it; the demo dies on insufficient funds.
- Browse other Gecko skills at `https://app.geckovision.tech/skills/`.

## Hosted Streamable HTTP MCP — *rolling out*

Coming soon at `https://mcp.geckovision.tech/mcp`. Lets MCP-only hosts (Cursor, Claude Desktop, Manus) skip the local install entirely. Your wallet is still the auth — same x402 payment flow, but the server runs in the cloud. When live, paste this into your MCP config:

```json
{
  "mcpServers": {
    "gecko": {
      "transport": "streamable-http",
      "url": "https://mcp.geckovision.tech/mcp"
    }
  }
}
```

Status: check `https://app.geckovision.tech/status` before relying on this in production.

---

## Change log

- **v3 (2026-05-07):** tool count 3 → **19** (full surface visible to Claude Code now); added `paysh_manifest` + `paysh_live` retrieval sources (pay.sh — 5 meta-skills + 72 catalog providers, 21 neobank-relevant); added `bazaar_manifest` + `bazaar_live` retrieval sources (Coinbase Agentic Wallet marketplace — 50 of 683 services pinned, 8 neobank-relevant); hosted Streamable HTTP MCP at `mcp.geckovision.tech/mcp` rolling out.
- v2 (2026-04-15): added `gecko_classify`, `gecko_route`, `gecko_advise`, `gecko_plan`, memory tools.
- v1 (2026-03-01): initial 3 tools (`research`, `ask`, `sources`).

---

*Builder Bootstrap Platform · geckovision.tech · No API keys. Just a wallet.*
