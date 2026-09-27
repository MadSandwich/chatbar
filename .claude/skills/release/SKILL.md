---
name: release
description: Commit pending changes, tag the version in ChatBar.VERSION as vX.Y.Z, and push both to origin, which publishes the release to CurseForge. Run with /release.
argument-hint: "[commit subject]"
disable-model-invocation: true
allowed-tools: Bash(bash .claude/skills/release/preflight.sh), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git tag:*), Bash(git push --atomic origin:*)
---

# Release ChatBar

Ship the version in `ChatBar.VERSION` ([ChatBar.lua](../../../ChatBar.lua)): commit, annotated tag `vX.Y.Z`, push. Pushing the tag triggers [release.yml](../../../.github/workflows/release.yml), which packages the addon with BigWigsMods/packager and uploads it to CurseForge. That upload can't be taken back, so every problem below stops the run instead of being worked around.

This skill does not bump the version or write release notes. Both happen before `/release` is run.

## 1. Preflight

Run with the Bash tool:

```bash
bash .claude/skills/release/preflight.sh
```

- `BLOCKED: ...`: stop, report the reason, change nothing.
- `WARN: ...`: show the warnings and ask the user whether to continue.
- Otherwise use the printed `VERSION`, `TAG` and `BRANCH` in the steps below. The status list after `--- status` is what the commit would contain.

## 2. Commit

Skip this step if the status list is empty. The tag then goes on the current `HEAD`.

What goes in:
- Staged changes only: commit the index as it is.
- Unstaged tracked changes only: stage them with `git add -u`.
- Both staged and unstaged: ask which the user wants. They may have staged a subset on purpose.
- Untracked files: never add them silently. List them and ask. A new `.lua` file that `ChatBar.toc` loads almost certainly belongs in the release.

Read `git diff --cached` and the `## VERSION` section of [RELEASE_NOTES.md](../../../RELEASE_NOTES.md), then write the message in the repo's style:

- Subject: Conventional Commit prefix (`feat:`, `fix:`, or `chore:` for a pure bump), a capitalized imperative summary, and ` and bump version to X.Y.Z` when the commit also carries the bump. Examples from history: `fix: Restyle template checkbox labels and bump version to 3.0.1`, `chore: Bump version to 2.4.1`.
- If `$ARGUMENTS` is non-empty, use it verbatim as the subject.
- Body: a few short paragraphs wrapped at 72 columns saying what changed and why.
- End with the Co-Authored-By trailer this session specifies.

Commit through a heredoc so quoting survives:

```bash
git commit -F - <<'EOF'
<subject>

<body>

<trailer>
EOF
```

Never use `--amend` or `--no-verify`. If a hook fails, stop and report it.

## 3. Tag

```bash
git tag -a "$TAG" -m "Release $VERSION"
```

Every existing tag is annotated with a `Release X.Y.Z` message. Keep it that way. The packager marks a tag containing `alpha` or `beta` (for example `v3.2.0-beta1`) as that release type on CurseForge. Any other tag becomes a full release.

## 4. Push

```bash
git push --atomic origin "$BRANCH" "$TAG"
```

`--atomic` lands the branch and the tag together or not at all. A tag without its commit, or a commit without its tag, leaves the release half-published.

If the push fails, don't retry with `--force`. Report the error and leave the local commit and tag as they are. If the user wants to abandon the release, `git tag -d "$TAG"` is safe because the tag never reached origin.

## 5. Report

Tell the user:
- the commit hash and subject (`git log -1 --format='%h %s'`)
- the tag that was pushed
- that the build runs at https://github.com/MadSandwich/chatbar/actions

## Guardrails

- Never move, delete or force-push a tag that is already on origin. Its CurseForge upload has already happened.
- Never force-push the branch.
- If preflight fails, fix nothing on your own, not even an obvious fix like bumping `ChatBar.VERSION`. Report it and let the user decide.
