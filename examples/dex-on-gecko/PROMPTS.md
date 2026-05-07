# dex-on-gecko — example prompts

Paste any of these into Claude Code after registering the Gecko MCP.

---

## Validation (pro tier — full 5-voice debate)

```
Use gecko_research with tier=pro:

I want to ship a Solana CLMM DEX with concentrated liquidity, MEV-resistant
routing via Jito bundles, and Pyth oracles for price discovery. V1 in 4 days.
How does this differentiate from Orca's Whirlpools, Raydium's CLMM, and
Meteora's DLMM — and what concrete signals falsify the wedge within 14 days?
```

Expected: REFINE or PIVOT. Surviving dissent likely flags MEV exposure or oracle latency.

## Quick taxonomy classification ($0.10)

```
Use gecko_classify on:
"a Solana DEX with cross-chain settlement via x402 micropayments
for routing fees"
```

## Follow-up Q&A (free under quota)

```
Use gecko_ask on session <id>:
"What does the architect voice say about MEV mitigation specifically?
Quote verbatim."
```

## Sprint plan from session ($0.25)

```
Use gecko_plan on session <id> with tier_preset=balanced
```

Returns the 5-voice advisor panel (CEO, CTO, BM, PM, Staff Manager) → sprint outline.

## Shareable HTML report ($0.05)

```
Use gecko_report on session <id> with format=html
```

Returns a standalone HTML doc you can paste into the placeholder, post on Twitter, or hand to a partner.

---

## Smoke-test budget

| Tool | Cost |
|---|---|
| `gecko_classify` | $0.10 |
| `gecko_research` (pro) | $0.75 |
| `gecko_ask` (post-quota) | $0.01 |
| `gecko_plan` | $0.25 |
| `gecko_report` | $0.05 |
| **Total** | **~$1.16 USDC** |

5 minutes wall-clock. Wallet handles x402 challenges silently if funded.
