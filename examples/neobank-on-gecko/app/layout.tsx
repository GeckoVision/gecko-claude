export const metadata = {
  title: "Neobank on Gecko",
  description: "Example app consuming Gecko via MCP from Claude Code.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body style={{ margin: 0, background: "#fafafa", color: "#111" }}>
        {children}
      </body>
    </html>
  );
}
