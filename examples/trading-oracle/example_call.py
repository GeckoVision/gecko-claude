"""Reference: end-to-end trading-oracle flow.

Holds the user's devnet keypair LOCALLY. Calls Gecko via MCP for a
verdict (orchestrated by Claude Code, not by this script). Hands intent
shaping to solana-claude's defi-engineer agent. Submits to devnet only
when explicitly invoked.

This file is a helper for the Claude Code session — it's NOT the
orchestrator. The orchestrator is the LLM in the Claude Code session
itself, which has the Gecko MCP mounted and calls gecko_research /
gecko_advise / etc as needed.

Gecko never sees a private key. The keypair stays here, on the user's
machine.
"""

from __future__ import annotations

import asyncio
import json
import os
from pathlib import Path

DEVNET_RPC = os.environ.get("SOLANA_DEVNET_RPC", "https://api.devnet.solana.com")
KEYPAIR_PATH = Path(os.environ.get(
    "SOLANA_DEVNET_KEYPAIR",
    str(Path.home() / ".config/solana/devnet-trader.json"),
))


def _load_keypair_lazy():
    """Load the user's devnet keypair. Lazy-imports solana/solders so this
    file can be read without those deps installed."""
    from solders.keypair import Keypair  # noqa: WPS433 (lazy by design)

    secret = json.loads(KEYPAIR_PATH.read_text())
    return Keypair.from_bytes(bytes(secret))


async def submit_signed_tx_devnet(unsigned_tx_b64: str) -> str:
    """Sign + submit a base64 versioned tx to devnet.

    Mirrors `signAndSend` from gecko-social-fi-creators-api/src/services/
    kamino.service.ts:107-121.

    Lazy imports so importing this module doesn't require solana/solders.
    Caller is the Claude Code session (or an agent running locally with
    SOLANA_DEVNET_KEYPAIR set), NOT Gecko.
    """
    import base64
    from solana.rpc.async_api import AsyncClient  # noqa: WPS433
    from solders.transaction import VersionedTransaction  # noqa: WPS433

    keypair = _load_keypair_lazy()
    raw = base64.b64decode(unsigned_tx_b64)
    vtx = VersionedTransaction.from_bytes(raw)
    signed = VersionedTransaction(vtx.message, [keypair])
    async with AsyncClient(DEVNET_RPC) as client:
        resp = await client.send_raw_transaction(bytes(signed))
        sig = resp.value
        await client.confirm_transaction(sig, commitment="confirmed")
        return str(sig)


def main() -> None:
    """Safe-to-run-without-env entry point.

    This script is intentionally NOT the orchestrator. Run it standalone
    to confirm the file is readable; real flow happens in the Claude Code
    session with the Gecko MCP mounted.
    """
    print("trading-oracle example helper")
    print("=" * 40)
    print(f"DEVNET_RPC      = {DEVNET_RPC}")
    print(f"KEYPAIR_PATH    = {KEYPAIR_PATH} (exists: {KEYPAIR_PATH.exists()})")
    print()
    print("This script is a HELPER, not the orchestrator. The Claude Code")
    print("session with the Gecko MCP mounted is the orchestrator. It will:")
    print("  1. Call gecko_research / gecko_advise via MCP for a verdict.")
    print("  2. Hand the verdict to solana-claude's defi-engineer agent.")
    print("  3. (Optional) Use submit_signed_tx_devnet() to fire a devnet tx.")
    print()
    print("To wire devnet execution:")
    print("  - solana-keygen new --outfile ~/.config/solana/devnet-trader.json")
    print("  - solana airdrop 2 -u devnet -k ~/.config/solana/devnet-trader.json")
    print("  - Then submit_signed_tx_devnet(<base64-unsigned-tx>) returns a sig.")


if __name__ == "__main__":
    asyncio.get_event_loop()  # touch the event loop to confirm asyncio works
    main()
