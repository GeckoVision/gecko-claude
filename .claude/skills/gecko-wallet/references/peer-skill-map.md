# Peer skill map

Every chain-touching op delegates. This file is the source of truth for which peer skill owns which intent class. Update it when a new wallet/facilitator peer skill lands (SendAI, Backpack, Cloudflare, awal).

## Intent class → peer skill

| Intent class | Signals | Peer skill | Why |
|---|---|---|---|
| Pure wallet read | balance, history, addresses, holdings, "what's my wallet worth", export, status | `okx-agentic-wallet` | Owns the auth + read surface for OKX OnchainOS. Has its own Step 0 router so we hand off the original prompt and let it resolve. |
| Trade verb without judgment | "swap X to Y", "buy", "sell", "convert", "best route" — no judgment marker | `okx-dex-swap` | Owns aggregated DEX swaps across 20+ chains. Its Step 0 already chains into `okx-dapp-discovery` if the user names a venue, so re-routing here is safe even on ambiguous prompts. |
| Named DApp + action | DApp name (Aave, Hyperliquid, Lido, Raydium, Kamino, Orca, Meteora, Pendle, Uniswap, pump.fun, etc.) + action verb | `okx-dapp-discovery` | The DApp's own plugin is the correct executor — it knows the protocol's surface area (deposit, stake, claim, etc.) better than aggregated swap routing. |
| Bridge / cross-chain transfer | "bridge", "send to <chain>", "move USDC from sol to base" | `okx-onchain-gateway` | Owns the cross-chain transfer surface. When judgment is present ("should I bridge now"), this skill runs the oracle first and only hands off after user confirms. |
| Contract approval scan / safety check | "is this contract safe", "scan this approval", "is X a honeypot" | `okx-security` | Owns the risk scan surface. Always run before any `contract-call` that touches an unfamiliar contract. |
| Approval execution (after safety scan) | "approve X for spender" (one-off ERC-20 approval primitive) | `okx-agentic-wallet` (`contract-call`) | The wallet skill owns the broadcast. Cap to need + 10%; never unlimited (hard rule from the OKX skill). |
| Transaction audit / "what did this tx do" | "look up tx <hash>", "what did this transaction do" | `okx-audit-log` | Owns the audit-log surface; pairs naturally with `okx-agentic-wallet history`. |

## Judgment routing (class C)

When the user's prompt carries a "should I" / "is it the right time to" / "is now a good time" marker, the wallet skill stays in scope and calls `gecko_trade_research` before dispatching. The verdict envelope determines the dispatch target:

| Oracle verdict | Action |
|---|---|
| `act` | Read verdict + top citation back to the user; ask to confirm; on confirm, dispatch to the peer skill that owns the underlying action (swap → `okx-dex-swap`, bridge → `okx-onchain-gateway`, etc.). |
| `defer` | Surface the verdict + the reason for deferral; ask the user whether to wait, tighten the question, or proceed anyway. Never dispatch silently on `defer`. |
| `pass` | Surface the verdict + surviving dissent verbatim; do NOT dispatch. Ask the user how to proceed. If they insist, dispatch but log the surviving dissent in the hand-off message so the peer skill sees it. |

## Future peer skills (placeholder rows)

Add a row here when the upstream peer skill ships. The Step 0 router in `SKILL.md` picks up new rows automatically as long as the intent signals are kept tight.

| Wallet / facilitator | Peer skill name (when shipped) | Status |
|---|---|---|
| SendAI Solana Agent Kit | `sendai-wallet`, `sendai-swap` | Not yet wired. |
| Backpack | `backpack-wallet`, `backpack-swap` | Not yet wired. |
| Cloudflare x402 facilitator | n/a (transport, not a wallet) | Used by the oracle, not surfaced here. |
| awal | n/a (parallel transport) | Same as above. |

## Hard rules

- Never duplicate an `onchainos` call. If a chain touch is needed and the peer skill owns it, dispatch — don't reimplement.
- Never broadcast from this skill. The peer skill owns the broadcast surface and the user-confirmation gates.
- Never call the oracle on class A or class B intents. The wedge is judgment-grounding, not blanket grounding — pay only when the user is actually asking for judgment.
- Wallet/facilitator neutrality is non-negotiable. The same router must work for SendAI and Backpack the day their peer skills land.
