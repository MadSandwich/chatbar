#!/usr/bin/env bash
# Release preflight for ChatBar.
#
# Reads ChatBar.VERSION and checks that it can be committed, tagged and pushed.
# Prints KEY=value lines followed by the working-tree status. A BLOCKED: line
# (exit 1) means the release must not go ahead; WARN: lines need the user's
# say-so before continuing.
set -u

root=$(git rev-parse --show-toplevel) || exit 1
cd "$root" || exit 1

fail() { echo "BLOCKED: $*"; exit 1; }
warn() { echo "WARN: $*"; }

version=$(sed -n 's/^ChatBar\.VERSION[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' ChatBar.lua | head -n1)
[ -n "$version" ] || fail "could not find ChatBar.VERSION in ChatBar.lua"
echo "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$' \
    || fail "ChatBar.VERSION \"$version\" is not X.Y.Z or X.Y.Z-suffix"
tag="v$version"

branch=$(git symbolic-ref --quiet --short HEAD) || fail "HEAD is detached; check out a branch first"

# --tags also updates the remote-tracking branches, so the checks below see
# both tags pushed from elsewhere and commits the local branch is missing.
git fetch --quiet --tags origin || fail "git fetch origin failed"

git rev-parse -q --verify "refs/tags/$tag" >/dev/null \
    && fail "tag $tag already exists; bump ChatBar.VERSION first"

# Compare X.Y.Z only: sort -V ranks 3.1.0-beta1 above 3.1.0, which would block
# promoting a beta to its final release. Equal cores are fine because the
# tag-exists check above already rules out an exact repeat.
latest=$(git tag --list 'v[0-9]*' --sort=-v:refname | head -n1)
if [ -n "$latest" ]; then
    core=${version%%-*}
    latest_core=${latest#v}
    latest_core=${latest_core%%-*}
    highest=$(printf '%s\n%s\n' "$latest_core" "$core" | sort -V | tail -n1)
    [ "$highest" = "$core" ] || fail "$tag is lower than the latest tag $latest"
fi

upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null) || upstream=""
if [ -n "$upstream" ]; then
    behind=$(git rev-list --count "HEAD..$upstream")
    [ "$behind" -eq 0 ] || fail "$branch is $behind commit(s) behind $upstream; pull first"
else
    warn "$branch has no upstream; the push will create origin/$branch"
fi

[ "$branch" = "develop" ] || warn "releasing from $branch, not develop"

grep -Eq "^## ${version//./\\.}([[:space:](]|$)" RELEASE_NOTES.md \
    || warn "RELEASE_NOTES.md has no \"## $version\" section"

echo "VERSION=$version"
echo "TAG=$tag"
echo "BRANCH=$branch"
echo "UPSTREAM=${upstream:-none}"
echo "LATEST_TAG=${latest:-none}"
echo "--- status"
git status --short
