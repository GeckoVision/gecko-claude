export const metadata = {
  title: "DEX on Gecko",
  description: "Example: scaffold a Solana DEX using Gecko via MCP from Claude Code.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body style={{ margin: 0, background: "#0e1116", color: "#e6edf3" }}>
        {children}
      </body>
    </html>
  );
}
