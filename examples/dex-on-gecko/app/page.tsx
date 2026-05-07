export default function Page() {
  return (
    <main
      style={{
        fontFamily: "ui-monospace, SFMono-Regular, monospace",
        maxWidth: 760,
        margin: "4rem auto",
        padding: "0 1.5rem",
        lineHeight: 1.6,
      }}
    >
      <h1 style={{ fontSize: "2rem", marginBottom: "0.5rem" }}>DEX on Gecko</h1>
      <p style={{ color: "#8b949e", marginTop: 0 }}>
        Example: a builder consumes Gecko via MCP from Claude Code to scaffold
        a Solana CLMM DEX with concentrated liquidity, MEV-resistant routing,
        and Pyth oracles.
      </p>

      <p>
        Gecko is the <strong>insight layer</strong>. This app is the{" "}
        <strong>render layer</strong>. Run <code>gecko_research</code> from
        Claude Code with{" "}
        <code>--vertical dex --tier pro</code>, then paste a cited build
        artifact (V1 scope, a chunk, or the validation summary) into the block
        below.
      </p>

      <h2 style={{ fontSize: "1.1rem", marginTop: "2rem" }}>
        Build artifact (paste from Claude Code)
      </h2>
      <pre
        style={{
          background: "#161b22",
          border: "1px solid #30363d",
          borderRadius: 6,
          padding: "1rem 1.25rem",
          fontSize: 13,
          overflowX: "auto",
          color: "#e6edf3",
        }}
      >{`// Example placeholder — replace with the V1 PRD or one cited chunk
// returned by gecko_research(tier=pro, vertical=dex).
//
// Expected sections:
//   - V1 scope (4-day ship)
//   - Surviving dissent (the unrefuted critic line — likely MEV-related)
//   - 3+ falsifiers with dated by-when
//   - Market landscape vs Orca / Raydium / Meteora`}</pre>

      <p style={{ color: "#8b949e", fontSize: 13, marginTop: "2rem" }}>
        See <a href="https://github.com/ernanibmurtinho/gecko-claude/blob/main/examples/SMOKE_TEST.md" style={{ color: "#58a6ff" }}>SMOKE_TEST.md</a> for the full step-by-step that produces this artifact in 5 minutes for ~$1.16 USDC.
      </p>
    </main>
  );
}
