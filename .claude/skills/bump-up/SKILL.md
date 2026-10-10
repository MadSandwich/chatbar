---
name: bump-up
description: Check Blizzard's version server for new WoW client builds and, when a flavor ChatBar supports has a newer patch, add its Interface number to ChatBar.toc, bump ChatBar.VERSION and write the release notes. Run with /bump-up, or /bump-up check to only report.
argument-hint: "[check]"
allowed-tools: Bash(bash .claude/skills/bump-up/check.sh), Bash(git tag --list:*), WebSearch, WebFetch(domain:warcraft.wiki.gg)
---

# Bump up ChatBar's Interface list

A client whose patch isn't in the `## Interface:` list of [ChatBar.toc](../../../ChatBar.toc) shows ChatBar as out of date. This skill finds such patches, checks what they change in the API, adds their Interface numbers and prepares a patch release. It does not commit, tag or push; `/release` does that afterwards.

## 1. Check

Run with the Bash tool:

```bash
bash .claude/skills/bump-up/check.sh
```

The script reads every public WoW product on `us.version.battle.net/v2`, in every region, and compares each build with the TOC. It prints `TOC=...`, one row per product build, then a summary:

- `NEW: <interface> <version> <products>`: a newer patch of a flavor the TOC already lists. Exit code 2.
- `UNTRACKED: <interface> <version> <products>`: a flavor the TOC doesn't list, such as TBC Anniversary (2.5.6) or CN-only Titan Reforged (3.80.2). Never added by this skill. Adding a flavor is a support decision for the user, not a bump.
- `TOC is current`: no NEW lines. Exit code 0.
- `ERROR: ...` (exit 1): stop and report it.
- `WARN: could not read <product>`: say so in the report, because a NEW build on that product would have been missed.

If there are no NEW lines, tell the user nothing needs bumping, list the UNTRACKED lines in one sentence, and stop. If `$ARGUMENTS` is `check`, report the summary and stop here even when NEW lines exist.

Reading the rows:

- Interface = major × 10000 + minor × 100 + patch: 12.1.5 → `120105`, 1.15.10 → `11510`.
- The flavors and the products that carry them:

  | Flavor | Version | Live product | Test products |
  | --- | --- | --- | --- |
  | Retail (Midnight) | 12.x | `wow` | `wowt`, `wowxptr`, `wow_beta` |
  | WoW: Forever | 1.60.x | `wow_classic_beta`, `wow_cn_beta` | |
  | Mists Classic | 5.5.x | `wow_classic` | `wow_classic_ptr` |
  | Classic Era | 1.15.x | `wow_classic_era` | `wow_classic_era_ptr` |

- Builds on test products count. The repo adds a patch's number while it is still on the PTR, so ChatBar isn't flagged out of date on release day: 3.1.1 added `120105` while live Retail was 12.1.0.
- An UNTRACKED major on `wow`, `wowt`, `wowxptr`, `wow_beta`, `wow_classic` or `wow_classic_ptr` (13.0 on the beta, or `wow_classic` moving past Mists) is the next expansion of a supported flavor. Don't add it. Point it out to the user, because a new expansion needs a code review, not just a new number. `wow_classic_era_ptr` also hosts other Classic flavors (it carried TBC Anniversary 2.5.6 in October 2026), so an UNTRACKED build there usually isn't Era's successor.

## 2. Check each new patch's API changes

For every NEW patch, find what it removed or changed. warcraft.wiki.gg has `https://warcraft.wiki.gg/wiki/Patch_X.Y.Z/API_changes` for most Retail patches. For a Classic patch, search for its API changes. Grep ChatBar's `.lua` files for each removed or renamed function, event, CVar and widget method.

- **Nothing ChatBar uses changed:** note the specifics for the release notes. 3.1.1 named what 12.1.5 removed and why ChatBar doesn't care.
- **Something ChatBar uses changed:** stop before editing. List the call sites and what changed. The fix is its own change, and the bump goes with it.
- **No change list found** (common for small Classic patches): say so in the report and the release notes. Don't claim the patch was checked.

## 3. Edit

Version: compare `ChatBar.VERSION` in [ChatBar.lua](../../../ChatBar.lua) with the latest tag (`git tag --list 'v*' --sort=-v:refname`).

- If they match, bump the patch number (3.1.1 → 3.1.2).
- If `ChatBar.VERSION` is already ahead, an unreleased bump is pending. Keep its version and add to its release-notes section.

Update the same files the 3.1.1 bump did (commit `ef7c8f5`):

- **[ChatBar.toc](../../../ChatBar.toc)**
  - Line 1 (`# Retail (Midnight) 12.1.5 | Forever ...`): each flavor's newest version.
  - `## Interface:`: add the number inside its flavor's group, ascending within the group. Groups go Retail, Forever, Mists Classic, Classic Era.
  - Never remove an existing number: an older client may still be live in some region, and pruning is the user's call.
- **[ChatBar.lua](../../../ChatBar.lua)**: `ChatBar.VERSION`.
- **[README.md](../../../README.md)**, "Supported Clients" table: set Version to the flavor's newest version and list the Interface numbers newest first.
- **[.github/copilot-instructions.md](../../../.github/copilot-instructions.md)**, "Version Information": `Addon Version`, and the same table.
- **[RELEASE_NOTES.md](../../../RELEASE_NOTES.md)**: a new `## X.Y.Z` section at the top, or the pending one. Write one bullet per patch in the 3.1.1 style: `- **Updated for patch 12.1.5** (Interface 120105).`, then the API finding from step 2.

Don't touch code, `.pkgmeta` or the release workflow.

## 4. Verify

Run the script again. It must print `TOC is current` and exit 0. A NEW line that is still there means an Interface number was mistyped or missed.

## 5. Report

Tell the user:

- each new build: version, Interface number, product, and whether it is live or test
- the API-change result for each patch
- the new `ChatBar.VERSION` and the files changed
- that `/release` commits, tags and publishes it to CurseForge. Don't commit here.
