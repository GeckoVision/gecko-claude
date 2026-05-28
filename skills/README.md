# Gecko skills directory

Standalone skills that live ABOVE other marketplaces — the rigor layer
on copy-trading, grid bots, yield protocols, etc.

Each subdirectory is a self-contained skill with its own `SKILL.md` +
`grader.py` / `grade.py` / `package.json` + tests + examples.

## Current skills

| Skill | Status | Source repo |
|---|---|---|
| [`gecko-copy-trade-grader`](./gecko-copy-trade-grader/) | shipped (v0.1.0) | `gecko-mcpay-api/gecko-copy-trade-grader/` |

## Layout note — symlink + sync

These directories are **symlinks into `gecko-mcpay-api/`**. This keeps
source of truth in the Python repo (where harness logic + tests live)
while exposing the skill at `app.geckovision.tech/skills/...`.

**Locally** (Linux/macOS): symlinks resolve naturally; `git status`
treats them as files.

**On Vercel deploy**: Vercel does NOT follow cross-repo symlinks at
build time. Run `./skills/sync.sh` BEFORE pushing to convert the
symlinks to real-content copies, then commit the snapshot.

```bash
./skills/sync.sh          # rsync from ../gecko-mcpay-api into skills/
git status skills/        # verify content snapshot
git add skills/
git commit -m "chore(skills): sync from gecko-mcpay-api $(date +%F)"
git push
```

If you skip the sync, the Vercel build will publish empty directories.

## How to add a new skill

1. Build the skill inside `gecko-mcpay-api/` (it gets the full test +
   uv toolchain there).
2. Symlink into `gecko-claude/skills/`:
   ```bash
   ln -sf ../../gecko-mcpay-api/<your-skill> skills/<your-skill>
   ```
3. Reference it in the main `skill.md` (a row in the appropriate
   "Companion skills" or "Due-diligence skills" table).
4. Run `./skills/sync.sh` to materialize content.
5. Commit + push.
