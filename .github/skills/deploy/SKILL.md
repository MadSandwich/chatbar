---
name: deploy
description: 'Commit pending changes and create an annotated git tag for a ChatBar release. Use when asked to "deploy", "release", "tag and commit", "cut a release", "bump the version", or "publish" a new version. Handles version detection from ChatBar.lua, conventional commit messages, annotated vX.Y.Z tags, and stops for explicit confirmation before pushing (pushing a tag triggers the CurseForge release workflow).'
argument-hint: '[version] [commit message]'
---

# Deploy (Commit + Tag Release)

Commits staged/working changes and creates an annotated git tag for a new ChatBar version, matching this repo's existing conventions. **Never pushes without explicit user confirmation** — pushing a tag triggers [.github/workflows/release.yml](../../workflows/release.yml), which packages the addon and publishes it to CurseForge via the BigWigsMods packager. Treat push as a hard-to-reverse, shared-system action per operational safety rules.

## When to Use

- User says "deploy", "release this", "tag and commit", "cut a release", "bump version and tag", "publish this version".
- A version bump (`ChatBar.VERSION` in [ChatBar.lua](../../../ChatBar.lua)) and/or a new [RELEASE_NOTES.md](../../../RELEASE_NOTES.md) entry already exist and need to be committed + tagged.

## Conventions in This Repo (verified from git history)

- Tags are **annotated** and **v-prefixed**: `v2.4.1`, `v2.4.0`, `v2.3.0`, etc. Tag message is `Release X.Y.Z`.
- Commit messages follow Conventional Commits style: `feat:`, `fix:`, `chore:` prefixes (e.g. `chore: Bump version to 2.4.1`, `feat: Add channel history cycling with keybindings and localization support`).
- The single source of truth for the version number is the `ChatBar.VERSION` constant near the top of [ChatBar.lua](../../../ChatBar.lua) (NOT `ChatBar.toc`, which uses the `@project-version@` packager placeholder).
- [RELEASE_NOTES.md](../../../RELEASE_NOTES.md) has one `## X.Y.Z (Short Title)` heading per release, newest first.
- Remote is `origin` (GitHub: MadSandwich/chatbar). Default branch worked on is typically `develop`.
- Pushing ANY tag (`git push origin --tags` or a specific tag) triggers `.github/workflows/release.yml` (`on: push: tags: '**'`), which runs `BigWigsMods/packager` and publishes to CurseForge using the `CF_API_KEY` secret. This is a real, user-visible release — always confirm before pushing.

## Procedure

1. **Determine the version.**
   - If the user supplied a version as an argument, use it.
   - Otherwise, read the `ChatBar.VERSION = "X.Y.Z"` line in [ChatBar.lua](../../../ChatBar.lua).
   - Cross-check that [RELEASE_NOTES.md](../../../RELEASE_NOTES.md) has a matching `## X.Y.Z` heading. If it's missing, warn the user (don't silently add release notes without being asked).

2. **Check working tree state.**
   ```bash
   git status --short
   git tag --list | grep -F "vX.Y.Z"   # confirm the tag doesn't already exist
   ```
   If the tag already exists, stop and tell the user (retagging requires `-f` and is destructive to shared history — never do this without explicit confirmation).

3. **Stage and commit.**
   - Stage the relevant files (prefer explicit paths over blind `git add -A` if unrelated changes are present in the working tree).
   - Use a Conventional Commit message. If the user gave a message, use it; otherwise infer one from the changes (e.g. `feat: ...` for new functionality, `chore: Bump version to X.Y.Z` for a pure version bump).
   ```bash
   git add <files>
   git commit -m "<type>: <summary>"
   ```
   Skip this step if there is nothing to commit (working tree already clean) — the tag can still point at the current `HEAD`.

4. **Create an annotated tag.**
   ```bash
   git tag -a "vX.Y.Z" -m "Release X.Y.Z"
   ```

5. **Show a summary and stop.**
   - Run `git log -1 --format='%H %s'` and `git tag --list -n1 vX.Y.Z` and show the result to the user.
   - Explicitly ask whether to push now, e.g.: "Commit and tag `vX.Y.Z` created locally. Push to `origin` now? This will trigger the CurseForge release workflow." Do not push until the user confirms.

6. **Push only after confirmation.**
   ```bash
   git push origin HEAD
   git push origin "vX.Y.Z"
   ```
   (Two separate pushes are intentional so a rejected/failed branch push doesn't leave a tag pushed without its commit, and vice versa.)

## Guardrails

- Never use `git tag -f`, `git push --force`, or `git tag -d` on an already-pushed tag without explicit, separate confirmation — these rewrite shared history / retrigger releases.
- Never push directly to `main`/`master` if the repo's default branch differs from the current branch — confirm the target branch with the user if ambiguous.
- If `ChatBar.VERSION` was not bumped since the last tag, ask the user before tagging a duplicate version.
