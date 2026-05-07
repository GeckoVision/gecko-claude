# neobank-on-gecko

Minimal example: a builder uses Claude Code + Gecko (via MCP) to scaffold a Solana neobank with USDC card-issuing.

Gecko is the **insight layer**. This app is the **render layer**. The MCP server returns structured, cited insights; you paste the build artifact into the placeholder UI.

See parent: [`../../README.md`](../../README.md).

## Layout assumption

This `.mcp.json` resolves Gecko via a sibling clone:

```
~/code/
  gecko-claude/                 <- this repo
    examples/neobank-on-gecko/
  gecko-mcpay-api/              <- Python backend (sibling)
```

Clone both at the same level. If your layout differs, edit `--directory` in `.mcp.json`.

## Setup

```bash
git clone https://github.com/ernanibmurtinho/gecko-claude.git
git clone https://github.com/ernanibmurtinho/gecko-mcpay-api.git
cd gecko-claude/examples/neobank-on-gecko

npm install
claude code
```

Claude Code auto-discovers `.mcp.json` and registers the `gecko` server.

## First query

In Claude Code, type:

```
Use gecko_research to validate: build a Solana neobank with USDC card-issuing
```

More examples in [`PROMPTS.md`](./PROMPTS.md).

## What you'll see

`gecko_research` returns a structured response containing:

- **PRD** with V1/V2/V3 scope
- **Validation report** with at least 5 cited chunks
- **At least one citation from `paysh_*`** (pay.sh / x402 source provider) — confirms the wedge wiring path B is live
- A real Solana transaction signature (frames.ag wallet, ~$0.10 USDC)

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
