# gecko-trade-coach

> Build a deployable trade strategy where every rule is grounded by surviving dissent and investor-canon citations.

## What this is

A conversational Claude Code skill that coaches you through assembling a DEX spot-trading strategy. Unlike a vibe-bot generator, every decision in the flow gets checked against the **Gecko verdict oracle** (`gecko_trade_research` MCP tool) — which returns a verdict, surviving dissent, and citations from Howard Marks, Damodaran, Mauboussin, and live on-chain freshness data.

The output is a JSON strategy spec (validated against `schema.json`) where every rule carries the verdict_id, citation_ids, and dissent_id that justified it. The spec is ready to backtest, paper-trade, and dispatch to your execution rail of choice (OKX Agentic Wallet, SendAI, Backpack).

## What this is NOT

- Not a single-shot verdict tool. Use `gecko_trade_research` directly for that.
- Not an execution engine. The spec dispatches to existing execution skills — we don't sign your transactions.
- Not a strategy library. We coach you through assembling one; future versions will integrate the Attested Alpha Registry for curated picks.

## Install

The coach lives inside the `gecko-claude` scaffold. Install Gecko with:

```bash
curl -fsSL https://app.geckovision.tech/install.sh | bash
```

Then in Claude Code:

```
Use the gecko-trade-coach skill to build a trading strategy.
```

## Cost

The coach is free. Each `gecko_trade_research` call costs:
- **Basic:** $0.25 USDC (used inside the coach loop, ~5–10 calls per strategy)
- **Pro:** $0.75 USDC (used once at go-live for the final verdict)

Expected total per strategy: **$1.50–$3.50 USDC**, settled on Solana via x402.

## Output

A JSON strategy spec at `schema.json` conformance. Top-level fields:

- `name`, `version`, `vertical`, `protocol`, `chain`
- `entry`, `exit`, `sizing` — one of each
- `filter`, `risk` — optional + required respectively
- **`oracle_grounding`** — the wedge: per-rule verdicts + citations + dissent IDs
- `backtest`, `paper_trade` — populated by harnesses, not the coach
- `execution_rail` — where the spec dispatches on go-live
- `published` — set when published to a partner registry

## License

MIT.
