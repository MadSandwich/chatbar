#!/usr/bin/env bash
# Interface check for ChatBar.
#
# Compares the ## Interface: list in ChatBar.toc with the client builds that
# Blizzard's version server publishes for every public WoW product, in every
# region. Prints the TOC list, one row per product build, then a summary:
#   NEW: <interface> <version> <products>        newer build of a listed flavor
#   UNTRACKED: <interface> <version> <products>  a flavor the TOC doesn't list
# Exit 0 = TOC is current, 2 = NEW lines present, 1 = the check could not run.
set -u

root=$(git rev-parse --show-toplevel) || exit 1
cd "$root" || exit 1

base=https://us.version.battle.net/v2
# Dev, vendor, event, submission, NEV and livetest channels carry builds that
# aren't public yet (wowv3 had 12.1.7 before any PTR did), so they don't count.
internal='^wow(dev|v|e|z|nev|livetest)[0-9]*$'

fail() { echo "ERROR: $*"; exit 1; }
warn() { echo "WARN: $*"; }

toc=$(sed -n 's/^## Interface:[[:space:]]*//p' ChatBar.toc | head -n1 | tr -d ' \r')
[ -n "$toc" ] || fail "no ## Interface: line in ChatBar.toc"
echo "TOC=$toc"

summary=$(curl -sS -m 15 "$base/summary") || fail "could not reach $base/summary"
products=$(printf '%s\n' "$summary" | cut -d'|' -f1 | grep -E '^wow' | grep -Ev "$internal" | sort -u)
[ -n "$products" ] || fail "$base/summary lists no public WoW products"

# A product with no builds answers 404 "No matched data"; only a failed request
# is worth a warning. Rows are Region|BuildConfig|CDNConfig|KeyRing|BuildId|
# VersionsName|ProductConfig, one per region, and regions can differ (some
# products are CN-only), so every distinct VersionsName is kept.
rows=""
for p in $products; do
    out=$(curl -sS -m 15 "$base/products/$p/versions") || { warn "could not read $p"; continue; }
    for v in $(printf '%s\n' "$out" | grep -E '^[a-z]+\|' | cut -d'|' -f6 | sort -u); do
        rows="$rows$p $v"$'\n'
    done
done
[ -n "$rows" ] || fail "no product returned a build"

echo "--- products"
printf '%s' "$rows" | awk -v toc="$toc" '
BEGIN {
    n = split(toc, list, ",")
    for (i = 1; i <= n; i++) {
        d = list[i] + 0
        have[d] = 1
        maj = int(d / 10000)
        fam = maj "." (int(d / 100) % 100)
        if (!(fam in famMax) || d > famMax[fam]) famMax[fam] = d
        if (!(maj in majMax) || d > majMax[maj]) majMax[maj] = d
    }
}
{
    split($2, v, ".")
    iface = v[1] * 10000 + v[2] * 100 + v[3]
    fam = v[1] "." v[2]
    # Same major.minor as a listed number (12.1.7 vs 12.1.5) decides first;
    # otherwise the same major (12.2.0 vs 12.1.5). 12.0.1 on a stale beta is
    # older, not new. A major the TOC never lists is another flavor.
    if (iface in have)        status = "covered"
    else if (fam in famMax)   status = (iface > famMax[fam])  ? "NEW" : "older"
    else if (v[1] in majMax)  status = (iface > majMax[v[1]]) ? "NEW" : "older"
    else                      status = "untracked"
    printf "%-22s %-16s %-7s %s\n", $1, $2, iface, status

    if (status != "NEW" && status != "untracked") next
    key = status " " iface " " v[1] "." v[2] "." v[3]
    if (!(key in seen)) { seen[key] = $1; order[++k] = key }
    else seen[key] = seen[key] "," $1
}
END {
    print "--- summary"
    for (i = 1; i <= k; i++) {
        split(order[i], f, " ")
        label = (f[1] == "NEW") ? "NEW" : "UNTRACKED"
        printf "%s: %s %s %s\n", label, f[2], f[3], seen[order[i]]
        if (f[1] == "NEW") found = 1
    }
    if (!found) print "TOC is current"
    exit found ? 2 : 0
}'
