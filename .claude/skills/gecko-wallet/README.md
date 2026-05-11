# gecko-wallet

> wallet co-pilot. natural-language wallet ops, grounded by the gecko verdict oracle when judgment is in play.

## what this is

a claude code skill that classifies wallet intents and routes them to the right okx onchainos peer skill. when the user's request carries a value-judgment ("should i bridge USDC now", "is it the right time to top up SOL"), it pauses and calls the gecko verdict oracle (`gecko_trade_research`) first, surfaces the verdict + surviving dissent + citations, then hands off for execution.

three classes of intent, four destinations:

- pure wallet read → `okx-agentic-wallet`
- trade verb without judgment → `okx-dex-swap`
- trade verb WITH judgment → stay, call the oracle, then hand off to the right peer
- named dapp + action → `okx-dapp-discovery`

## what this is NOT

- not an execution engine. it never broadcasts, never holds keys, never duplicates an `onchainos` call. every chain touch is a delegation.
- not a single-shot verdict tool. for "should i deposit X into Kamino" with no follow-on wallet op, call `gecko_trade_research` directly.
- not a strategy builder. for that, use `gecko-trade-coach`.

## install

the skill ships inside the `gecko-claude` scaffold. install gecko with:

```bash
curl -fsSL https://app.geckovision.tech/install.sh | bash
```

then in claude code:

```
use the gecko-wallet skill to help me decide if i should bridge USDC to Base right now.
```

## cost

the skill is free. each `gecko_trade_research` call costs $0.25 USDC (basic tier — what this skill uses by default), settled on solana via x402. pure-read and trade-without-judgment intents re-route immediately and cost nothing.

expected per-session cost: **$0 – $1.00 USDC**, depending on how many judgment calls you make.

## sample intents

- "should i bridge USDC to base right now"
- "do i have enough SOL for a meteora deposit"
- "is now a good time to rotate my SOL into USDC"
- "fund my agent wallet with $50 of SOL"
- "what's my wallet worth"
- "swap 10 USDC to SOL"

the first three trigger an oracle call; the last three re-route immediately.

## license

MIT.
