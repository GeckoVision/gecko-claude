# Example prompts

Type these into Claude Code after `.mcp.json` registers the `gecko` server.

## 1. Validate the idea (paid, ~$0.10 USDC)

```
Use gecko_research to validate: build a Solana neobank with USDC card-issuing
```

Returns: PRD (V1/V2/V3), validation report with cited chunks, Solana tx signature.

## 2. Free follow-up Q&A

```
Use gecko_ask: what KYC providers integrate with x402 on Solana?
```

Grounded in the indexed sources from the active session.

## 3. List sources for a vertical

```
Use gecko_sources for vertical: neobank
```

Lists every indexed source with chunk counts. Look for `paysh_*` entries — confirms pay.sh wedge wiring is live.

## Tips

- Run `gecko_research` once per idea; subsequent `gecko_ask` calls are free.
- Copy the V1 scope into `app/page.tsx` to render.
- Cited chunks include source URLs — verify any technical claim before building.
