# Examples — smoke-test runbook

End-to-end test for the Gecko MCP from a clean machine. Run this before any demo, partner pitch, or external user-test. ~5 minutes wall-clock, ~$1.16 USDC.

If a step fails, halt and surface the error verbatim. **Do not improvise around a broken step** — the demo dies on insufficient funds, expired wallet auth, or a stale image more often than on bugs.

---

## 0 · Prerequisites

| Need | Where it's checked |
|---|---|
| `claude` CLI installed | `claude --version` |
| `node` 20+ + `npm` | `node --version` (only needed if you `npm run dev` the placeholder UI) |
| A Solana wallet with ≥$2 USDC | `gecko-mcp wallet balance` (after install via `install.sh`) — first-call discovery + 5-tool flow runs ~$1.16 IF prod is in `X402_MODE=live`. Currently in stub mode (free), confirm via `curl https://api.geckovision.tech/healthz` and check `payments` field. |
| Network access to `api.geckovision.tech` | `curl https://api.geckovision.tech/healthz` returns `{"status":"ok"}` |

If you need a wallet, run the public installer first:

```bash
curl -fsSL https://app.geckovision.tech/install.sh | bash
```

This installs `gecko-mcp`, sets up the frames.ag wallet via email + OTP (no browser needed), and creates `~/.agentwallet/config.json`. See [`skill.md`](../skill.md) for the full 4-step UX.

---

## 1 · Pick a vertical example

Two examples ship today:

```bash
git clone https://github.com/ernanibmurtinho/gecko-claude.git
cd gecko-claude/examples/neobank-on-gecko        # (or dex-on-gecko)
```

Both have the same shape. `.mcp.json` points at `https://api.geckovision.tech/mcp/` by default — no install needed beyond `claude code` reading the file.

## 2 · Verify the MCP connection

```bash
claude mcp list
```

Expected: `gecko` listed with status connected. If not, re-check `.mcp.json`:

```bash
cat .mcp.json
# expect "url": "https://api.geckovision.tech/mcp/"
```

If you need a smoke that doesn't go through Claude Code (e.g. CI), use raw curl:

```bash
curl -sS -X POST https://api.geckovision.tech/mcp/ \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' \
  | python3 -m json.tool | head -40
```

Expected: `result.tools` array with **19 entries** (gecko_research, gecko_ask, gecko_classify, gecko_plan, gecko_advise, gecko_route, gecko_review, gecko_scaffold, gecko_report, gecko_sources, gecko_precedents, gecko_available_sources, gecko_pulse, gecko_memory_save, gecko_memory_recall, gecko_memory_search, gecko_memory_query, gecko_resume, gecko_project_economics).

If `result.tools: []`, halt — the deployment is stale (this was the v0.2.24 fix). Pull v0.2.24+ and redeploy.

## 3 · Open Claude Code in the example dir

```bash
claude code
```

Confirm the Gecko tools show up (Claude Code surfaces them as `mcp__gecko__*` in the tool list).

## 4 · Run the 5-tool demo flow

Paste these into Claude Code one at a time. Each is a single MCP tool call; cost in USDC and target output below.

### Step 4.1 — `gecko_classify` ($0.10)

```
Use gecko_classify on this idea:
"a Solana-native USDC neobank with on-chain card-issuing for builders"
```

Expected: a JSON taxonomy with selected categories (likely `crypto`, `regulated`, `defi`) + a suggested-source list with priority weights.

### Step 4.2 — `gecko_research` ($0.75 pro tier, ~3 min)

```
Use gecko_research with tier=pro and tier_preset=balanced:
"I'm Caio, a developer. I want to ship a Solana-native USDC neobank with
on-chain card-issuing in 4 days. What's the smallest V1 that materially
differentiates from Coinbase Card, Crypto.com Card, Mercury, and Stripe
Agentic Commerce Protocol — and what concrete signals would falsify
the wedge within 14 days?"
```

**Capture the `session_id`** (a UUID). You'll use it for the next 3 steps.

**Demo-quality gates** to check before continuing:

- `verdict ∈ {REFINE, GO, PIVOT}` — `KILL` is rare with this prompt; if it happens, retry once
- `surviving_dissent.length ≥ 1` — proof of adversarial debate
- `next_steps.length ≥ 3` — proof of dated falsifiers
- `transaction_signature` present — proof of x402 settlement

If any gate fails, halt and surface the response.

### Step 4.3 — `gecko_ask` ($0.01 post-quota; first 100 free per session)

```
Use gecko_ask on session <UUID from step 4.2>:
"Quote verbatim the architect voice's V1 scope. Then quote the
critic's strongest unrefuted dissent."
```

Expected: a focused answer grounded in the same session's chunks, with cited markers.

### Step 4.4 — `gecko_plan` ($0.25)

```
Use gecko_plan on session <UUID> with tier_preset=balanced
```

Expected: the 5-voice Advisor Panel (CEO, CTO, BM, PM, Staff Manager) → a sprint plan synthesis. Voices are independent and EXPECTED to disagree.

### Step 4.5 — `gecko_report` ($0.05)

```
Use gecko_report on session <UUID> with format=html
```

Expected: an HTML payload (`{"html": "<full HTML doc>"}`). Save it to `/tmp/gecko_demo_<UUID>.html` and open in a browser. This is the shareable artifact you hand to a partner / Colosseum judge.

---

## 5 · (Optional) Render the placeholder UI

```bash
npm install
npm run dev
# open http://localhost:3000
```

Paste the V1 scope or one cited chunk from step 4.2's response into the `<pre>` block in `app/page.tsx`. Hot reload renders.

---

## 6 · Total budget + checklist

```
session_id:            <uuid from step 4.2>
verdict:               <REFINE | GO | PIVOT>
surviving_dissent:     ≥ 1
falsifiers (dated):    ≥ 3
total_x402_spend:      ~$1.16 USDC on Solana mainnet
report_html:           /tmp/gecko_demo_<uuid>.html
total_wall_clock:      ~5 minutes
```

If all six lines look right, the demo is green.

---

## Failure modes — what to do

| Symptom | Likely cause | Fix |
|---|---|---|
| `tools: []` from `/mcp` curl | Deployed image < v0.2.24 (uvicorn-loop registration bug) | Operator: pull v0.2.24+, redeploy ECS |
| `Invalid Host header` | New hostname not in `MCP_ALLOWED_HOSTS` | Operator: append to env var, redeploy (no code change) |
| `gecko_research` returns 402 then errors | Wallet has < $0.75 USDC | Top up via `gecko-mcp wallet show` → frames.ag onramp |
| Verdict comes back as `KILL` | Prompt was too vague or pessimistic | Retry once with the canonical prompt above; pro debates have variance |
| `gecko_report` 500 | Session ID typo or session in `interrupted` state | Re-paste the UUID from step 4.2's response verbatim |
| Citations all from Tavily, none from `paysh_*` / `bazaar_*` | FIX-12 source-routing gap (S23 work) | Verdict shape is correct; corpus depth is what S23 fills in. Demo continues. |
| First call hangs ~30s with no spinner | Cold-start on the ECS task | Wait one full call's worth, retry. Subsequent calls warm. |

---

## What this proves

- Hosted MCP is end-to-end functional: tool registry → x402 challenge → wallet sign → backend dispatch → cited response → shareable artifact
- Two verticals (neobank, DEX) work from the same MCP — proves the architecture isn't single-vertical
- The full 5-tool flow lands in 5 minutes for ~$1.16 — the unit-economics demo for partners
- Adversarial verdict shape is real: surviving dissent + dated falsifiers, not rubber-stamped output
