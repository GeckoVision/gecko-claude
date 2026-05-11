---
name: gecko-wallet
description: Gecko's wallet co-pilot. Natural-language wallet ops grounded by Gecko's verdict oracle when value-judgment is needed. Routes to okx-agentic-wallet / okx-dex-swap / sendai-wallet for execution; never holds keys, never executes directly. Triggers — gecko wallet, fund my agent, get me sol, do i have enough, grounded swap, should i swap, gas top-up with research, is now a good time to bridge, grounded wallet, judgment swap, oracle-checked swap.
license: MIT
version: "0.1.0"
metadata:
  author: gecko
  homepage: "https://geckovision.tech"
  oracle_tool: gecko_trade_research
  peer_skills:
    - okx-agentic-wallet
    - okx-dex-swap
    - okx-dapp-discovery
    - okx-onchain-gateway
    - okx-security
    - okx-audit-log
---

# Gecko Wallet

> Natural-language wallet ops, grounded by surviving dissent when the intent carries judgment. Execution stays with the peer skills — this one classifies intent, fetches the verdict when it matters, and hands off.

## Scope

- Wallet read, send, swap, bridge, approve, sign — every chain-touching op delegates to an OKX OnchainOS peer skill.
- **Wedge:** when the user asks a question with judgment baked in ("should I top up", "is now a good time to bridge", "do I need more SOL"), call `gecko_trade_research`, surface the verdict + surviving dissent + citations, then hand off to the right peer for execution.
- Execution-venue neutral by design. Today only OKX peers are wired; the same router works for SendAI and Backpack once their peer skills land.
- This skill never holds keys, never broadcasts, never duplicates an `onchainos` call. If a chain touch is needed, a peer skill does it.

## Step 0 — Re-route check (run before every other step)

Classify the user's intent before any tool call. Four classes, mirrored on the OKX agentic-wallet Step 0 pattern.

| Intent class | Signals | Action |
|---|---|---|
| **A. Pure wallet read** | balance, history, addresses, holdings, "what's my wallet worth", "show my SOL" | Re-route to `okx-agentic-wallet`. Do NOT call the oracle. |
| **B. Trade verb without judgment** | "swap 10 USDC to SOL", "buy 0.5 ETH", "sell my CAKE", "convert tokens" — no "should I", no "is now a good time" | Re-route to `okx-dex-swap`. Do NOT call the oracle. |
| **C. Trade verb WITH judgment** | "should I top up", "do I need SOL", "is now a good time to bridge", "should I swap before the unlock", "is it the right time to rotate to USDC" | **Stay.** Call `gecko_trade_research`, surface verdict + surviving dissent, then dispatch to the right peer once user confirms. |
| **D. Named DApp + action** | "deposit USDC into Aave", "stake on Lido", "long ETH on Hyperliquid" | Re-route to `okx-dapp-discovery`. The DApp's own plugin owns execution. |

Edge cases:

- "Fund my agent with $50 SOL" — class A read (find agent wallet from `~/.gecko/trade-agent/agents.json` if it exists) + class B send. Read first, then dispatch `okx-agentic-wallet send` to the agent address. No oracle call — funding an existing agent is not a judgment call.
- "Is it safe to approve X" — re-route to `okx-security` for the contract scan; that's a safety question, not a judgment-about-timing question.
- "Should I approve unlimited spend on Raydium" — class C (judgment) but the underlying op is an approval; call the oracle on the **decision** ("approve unlimited spend on Raydium"), then route the actual approval through `okx-security` first, then `okx-agentic-wallet contract-call`.

If you have already started running commands and only then realise a re-route applies, halt and invoke the correct skill — do not finish the wallet operation in this skill.

The wedge sits squarely on class C. Everything else delegates immediately.

## Step 1 — Preflight (only when staying in class C)

Run these checks before the first oracle call.

1. **Gecko MCP registered.** Verify `gecko_trade_research` is available in the current Claude Code session. If not, stop and say: *"This skill needs the Gecko MCP server for judgment-grounded ops. Install with: `curl -fsSL https://app.geckovision.tech/install.sh | bash` and restart Claude Code. For non-judgment wallet ops, use `okx-agentic-wallet` directly."*
2. **OKX OnchainOS CLI present.** Run `onchainos --version`. If missing, surface install guidance from the OKX skill bundle and stop — without execution rails we can't hand off after the verdict.
3. **Funding model.** This skill is free. The `gecko_trade_research` call costs $0.25 (basic) or $0.75 (pro). Default to basic inside the wallet loop; quote the cost in one line before the call.

## Step 2 — Intent → action map

The wedge cases. For each, the skill calls `gecko_trade_research` first (when judgment is present), surfaces the verdict + surviving dissent + citations, asks the user to confirm, and then dispatches to the named peer skill.

| User says | Class | Skill does |
|---|---|---|
| "I need SOL to finish this operation" | A → B | Read balance via `okx-agentic-wallet`; if below a sensible threshold (default 0.05 SOL on Solana, 0.01 ETH on EVM), decide swap source via internal heuristics (USDC first, then largest non-native holding); dispatch `okx-dex-swap`. No oracle call — operational top-up, not judgment. |
| "Should I bridge USDC to Base right now" | C | Call `gecko_trade_research` with `vertical=dex`, `idea="bridge USDC sol→base now"`; surface verdict + surviving dissent + citations; ask user to confirm before re-routing to `okx-onchain-gateway` for the bridge tx. |
| "Should I top up SOL before the unlock" | C | Call `gecko_trade_research` with `vertical=dex`, `idea="top up SOL before <event>"`; surface verdict; on `act` confirm, re-route to `okx-dex-swap`. On `defer` or `pass`, surface dissent and ask the user how to proceed. |
| "Fund my agent with $50 SOL" | A + B | Read agent wallet from `~/.gecko/trade-agent/agents.json` (if file exists); dispatch `okx-agentic-wallet send` to that address. No oracle call. |
| "What's my wallet worth" | A | Re-route to `okx-agentic-wallet` (pure read). |
| "Swap 10 USDC to SOL" | B | Re-route to `okx-dex-swap` immediately. No oracle call. |
| "Is it safe to approve X" | — | Re-route to `okx-security` for the contract scan. |
| "Should I rotate my SOL into USDC right now" | C | Call `gecko_trade_research` with `vertical=dex`, `idea="rotate SOL → USDC now"`; surface verdict; on confirm, re-route to `okx-dex-swap`. |
| "Should I approve unlimited spend on Raydium" | C + safety | Call `gecko_trade_research` on the decision; **then** re-route to `okx-security` for the contract scan; **then** `okx-agentic-wallet contract-call` for the actual approval (capped to need + 10%, never `type(uint256).max` — that's a hard rule from the OKX skill). |

For every class-C call, the verdict envelope landed in the response is the wedge proof. Read it back to the user in plain language — verdict, top citation, surviving dissent if any — before asking them to confirm the hand-off.

## Composition

Installed alongside the OKX OnchainOS skill bundle. This skill never duplicates an `onchainos` call — every chain-touching op is a delegation to the peer skill that owns that surface. The skill's job is **intent classification + judgment grounding**; execution is peer-owned.

Wallet/facilitator neutrality is preserved by design. The same Step 0 router works for SendAI's Solana Agent Kit or Backpack's wallet skill once their peer skills exist; today only OKX peers are wired. When a SendAI/Backpack peer skill lands, add a row to the peer-skill map at `references/peer-skill-map.md` and the router picks it up.

## Re-route table

If the user's intent is not wallet-shaped, route elsewhere:

| Intent | Skill |
|---|---|
| Pure wallet read (balance, history, addresses) | `okx-agentic-wallet` |
| Trade verb without judgment | `okx-dex-swap` |
| Named DApp + action | `okx-dapp-discovery` |
| Bridge ops (cross-chain transfer) | `okx-onchain-gateway` (after class-C oracle check, if judgment is present) |
| "Is this contract safe" / approval scans | `okx-security` |
| "What did this transaction do" / audit-log review | `okx-audit-log` |
| Build a full trading strategy from scratch | `gecko-trade-coach` |
| Single-shot judgment question with no chain action ("should I deposit USDC into Kamino?") | `gecko_trade_research` direct, not this skill |
| Validate a non-trading idea | `gecko_research` |

## Output contract

This skill emits **no JSON spec**. Its outputs are:

1. A short plain-language verdict read-back when class C fires (verdict, top citation, surviving dissent if any).
2. A dispatch to the right peer skill with the resolved parameters (chain, token, amount, recipient) baked in.
3. Optional audit-log line if `okx-audit-log` is wired and the user opted in.

No improvising. No oracle call → no judgment claim. Loud failure beats silent ungroundedness.

## References

- `references/peer-skill-map.md` — intent class → peer skill mapping with rationale. Update this when a new wallet/facilitator peer skill lands.
