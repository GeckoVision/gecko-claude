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
      <h1 style={{ fontSize: "2rem", marginBottom: "0.5rem" }}>
        Neobank on Gecko
      </h1>
      <p style={{ color: "#666", marginTop: 0 }}>
        Example: a builder consumes Gecko via MCP from Claude Code to scaffold
        a Solana neobank with USDC card-issuing.
      </p>

      <p>
        Gecko is the <strong>insight layer</strong>. This app is the{" "}
        <strong>render layer</strong>. Run <code>gecko_research</code> from
        Claude Code, then paste a cited build artifact (V1 scope, a chunk, or
        the validation summary) into the block below.
      </p>

      <h2 style={{ fontSize: "1.1rem", marginTop: "2rem" }}>
        Build artifact (paste from Claude Code)
      </h2>
      <pre
        style={{
          background: "#0b0b0b",
          color: "#e6e6e6",
          padding: "1rem",
          borderRadius: 6,
          overflowX: "auto",
          minHeight: 200,
          whiteSpace: "pre-wrap",
        }}
      >
        {`// Paste the gecko_research output here.
// Expected: V1 scope + at least 5 cited chunks,
// at least one from a paysh_* source.`}
      </pre>

      <p style={{ color: "#666", fontSize: "0.9rem" }}>
        See <code>PROMPTS.md</code> for example queries.
      </p>
    </main>
  );
}
