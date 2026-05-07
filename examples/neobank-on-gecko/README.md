# neobank-on-gecko

Minimal example: a builder uses Claude Code + Gecko (via MCP) to scaffold a Solana neobank with USDC card-issuing.

Gecko is the **insight layer**. This app is the **render layer**. The MCP server returns structured, cited insights; you paste the build artifact into the placeholder UI.

See parent: [`../../README.md`](../../README.md). Smoke-test runbook for all examples: [`../SMOKE_TEST.md`](../SMOKE_TEST.md).

---

## Setup

Two paths — pick whichever matches your environment.

### Path A — Hosted MCP *(default, no install)*

`.mcp.json` already points at `https://api.geckovision.tech/mcp/` (live, 19 tools, x402 wallet auth).

```bash
git clone https://github.com/ernanibmurtinho/gecko-claude.git
cd gecko-claude/examples/neobank-on-gecko
npm install
claude code
```

Claude Code reads `.mcp.json`, registers the `gecko` server, and you're in.

### Path B — Local stdio *(dev only, against unreleased gecko-mcpay-api)*

Requires a sibling clone of `gecko-mcpay-api` with `uv sync` run.

```
~/code/
  gecko-claude/                 <- this repo
    examples/neobank-on-gecko/
  gecko-mcpay-api/              <- Python backend (sibling)
```

```bash
claude code --mcp-config .mcp.local.json
```

---

## First query

In Claude Code, type:

```
Use gecko_research to validate: build a Solana neobank with USDC card-issuing
```

More examples in [`PROMPTS.md`](./PROMPTS.md). Each tool's price is in the parent [`skill.md`](../../skill.md) reference table.

## What you'll see

`gecko_research` (pro tier) returns a structured response containing:

- **PRD** with V1/V2/V3 scope
- **Validation report** with cited chunks
- **Surviving dissent** — at least one critic objection that survived the debate, with verbatim quote
- **Falsifiers** — dated next-steps that would kill or pivot the idea
- **5-voice debate transcript** (analyst, critic, architect, scoper, judge)
- A real Solana transaction signature (frames.ag wallet, ~$0.75 USDC for pro tier)

Paste the V1 scope or one cited chunk into the `<pre>` placeholder in `app/page.tsx` and run `npm run dev` to render.

## Run the placeholder UI

```bash
npm install
npm run dev
```

Open `http://localhost:3000`.

## Constraints

- No backend code lives in this example.
- No env vars, no secrets, no service-role keys. The MCP server handles auth itself via the user's wallet.
- This is a scaffold — `npm install` is run by the user, not committed artifacts.
