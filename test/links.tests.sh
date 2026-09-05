#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/assert.sh"
source "$SCRIPT_DIR/../shell/lib/psv.sh"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

test_case "every link source exists in the repo"
missing=0
while IFS='|' read -r src target; do
  [ -f "$ROOT/$src" ] || { echo "    missing source: $src"; missing=$((missing + 1)); }
done < <(psv_filter "$ROOT/linux/links.psv")
assert_equal "$missing" "0" "no missing sources"

# Reconstruct the original hardcoded SYMLINKS array (source:target per
# line) straight from git history, so both the count and the individual
# targets stay derived rather than hand-copied magic values.
old_links=$(git -C "$ROOT" show HEAD:common/create_symlinks.sh \
  | awk '/^SYMLINKS=\(/{flag=1;next} /^\)/{flag=0} flag' \
  | sed -E 's/^[[:space:]]*"//; s/"[[:space:]]*$//')

test_case "link map covers the same count as the old hardcoded array"
expected_count=$(echo "$old_links" | grep -c .)
actual_count=$(psv_filter "$ROOT/linux/links.psv" | wc -l)
assert_equal "$actual_count" "$expected_count" "link count matches old hardcoded array"

test_case "every link target matches the old hardcoded array"
mismatches=0
while IFS=':' read -r src expected_target; do
  [ -z "$src" ] && continue
  actual_target=$(psv_filter "$ROOT/linux/links.psv" | awk -F'|' -v s="$src" '$1==s{print $2}')
  if [ "$actual_target" != "$expected_target" ]; then
    echo "    target mismatch for $src: expected <$expected_target> actual <$actual_target>"
    mismatches=$((mismatches + 1))
  fi
done <<< "$old_links"
assert_equal "$mismatches" "0" "all targets match the original hardcoded array"

test_case "create_symlinks.sh no longer hardcodes a SYMLINKS array"
grep -q 'SYMLINKS=(' "$ROOT/common/create_symlinks.sh"
[ $? -ne 0 ]
assert_true $? "array is gone"

test_summary
