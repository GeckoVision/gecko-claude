---
name: trading-oracle
description: Solana DeFi trading research with Gecko's adversarial-debate verdict, hand-off to solana-claude's defi-engineer for Kamino-style intent, devnet execution.
---

# Trading Oracle (reference skill)

This skill demonstrates **Gecko's KaaS oracle pattern**:

1. **Gecko** provides grounded knowledge + adversarial verdict (this skill calls it via MCP).
2. **Superteam Brasil's `solana-claude` `defi-engineer` agent** owns Kamino / Jupiter / Drift / Raydium / Orca / Meteora intent shape.
3. **The user's chosen venue** (devnet here, mainnet via Kamino webapp / lana.ai elsewhere) settles.

Gecko never custodies funds, never signs transactions, never executes trades.

## Setup (one-paste)

```bash
# 1. Install solana-claude (Superteam Brasil bundle) for the defi-engineer agent.
curl -fsSL https://raw.githubusercontent.com/solanabr/solana-claude-config/main/install.sh | bash

# 2. Mount Gecko MCP — see .mcp.json in this directory.

# 3. (Optional) Generate a devnet keypair if you want to actually execute deposits.
solana-keygen new --outfile ~/.config/solana/devnet-trader.json
solana airdrop 2 -u devnet -k ~/.config/solana/devnet-trader.json
```

## Use

In Claude Code, paste:

> "Use the trading-oracle skill: should I deposit \$1 USDC into Kamino's USDC reserve right now? Use Gecko for grounded research, defi-engineer for intent shape, and execute on devnet."

The skill will:
1. Call `gecko_research` (via the mounted Gecko MCP) with `vertical=dex`, `idea` scoped to Kamino.
2. Receive a verdict with citations from Gecko's marketplace-paid corpus (currently Zerion portfolio chunks + Exa search chunks tagged per protocol).
3. Hand the verdict to `defi-engineer` for the Kamino-specific intent shape.
4. (Optional) Build a devnet deposit intent, sign with your devnet keypair, submit, return the signature.

## What this skill proves

- The **integration architecture**: a paid third-party skill calls Gecko via MCP and gets grounded answers backed by Bazaar-paid x402 sources.
- **Non-custodial boundary**: Gecko returns text + citations; signing and execution stay client-side.
- **Per-protocol corpus**: Gecko's 27 trading-oracle chunks are tagged with `protocol=[jupiter|kamino|pyth|drift|jito]` so retrieval can scope to one protocol.

## What's roadmap

- **More substantive corpus**: Bazaar listings other than Zerion / Exa have upstream issues (blockrun.ai is a static page, Venice uses non-standard SIWE x402, paysponge Perplexity gateway broken). As marketplaces mature, more chunks will land.
- **Solana-side x402** via paysh: requires a Solana-capable buyer (separate keypair scheme + Solana facilitator routing). Tracked as Phase 7.
- **Real Kamino mainnet execution**: out of scope for this reference. Use Kamino's web app, lana.ai, or your own integration.

## References

- Gecko MCP: `mcp.geckovision.tech` (19 tools)
- solana-claude: github.com/solanabr/solana-claude-config (Superteam Brasil)
- Gecko KaaS positioning: see `gecko-claude` README and `gecko-mcpay-api/docs/superpowers/specs/2026-05-08-trading-oracle-reference-skill-design.md`
