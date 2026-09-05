#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/assert.sh"
source "$SCRIPT_DIR/../shell/lib/psv.sh"

fixture="$(mktemp)"
cat > "$fixture" <<'INNER'
# a comment
@section|Modern CLI Tools

eza|Enhanced ls
INNER

test_case "strips comments and blank lines"
count=$(psv_filter "$fixture" | wc -l)
assert_equal "$count" "2" "two real records"

test_case "preserves field content"
first=$(psv_filter "$fixture" | head -1)
assert_equal "$first" "@section|Modern CLI Tools" "first record intact"

rm -f "$fixture"
test_summary
