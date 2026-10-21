#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/assert.sh"
export DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$DOTFILES/shell/functions.sh"

output=$(myenv)
# Same platform pick as myenv itself.
platform=linux; [ "$(uname -s)" = "Darwin" ] && platform=mac
CATALOG="$DOTFILES/$platform/packages.psv"

test_case "renders one marked line per catalog entry"
expected=$(grep -vc '^@section\|^#\|^$' "$CATALOG")
actual=$(echo "$output" | grep -c '✓\|✗')
assert_equal "$actual" "$expected" "line count matches catalog"

test_case "renders every section heading"
missing=0
while IFS='|' read -r key value; do
  echo "$output" | grep -qF "$value" || { echo "    missing section: $value"; missing=$((missing + 1)); }
done < <(grep '^@section|' "$CATALOG")
assert_equal "$missing" "0" "all sections rendered"

test_case "detects a tool that is definitely installed"
echo "$output" | grep -q "✓.*bash\|✓.*rg\|✓.*node"
assert_true $? "at least one known tool detected"

test_case "is data-driven: renders a fixture catalog, not the real one"
REAL_DOTFILES="$DOTFILES"
fixture_dir="$(mktemp -d)"
mkdir -p "$fixture_dir/linux" "$fixture_dir/mac" "$fixture_dir/shell/lib"
cat > "$fixture_dir/linux/packages.psv" << 'EOF'
@section|Fixture Section
zzz-not-a-real-tool|Fixture entry
EOF
# myenv picks the catalog by platform; same fixture either way.
cp "$fixture_dir/linux/packages.psv" "$fixture_dir/mac/packages.psv"
cp "$REAL_DOTFILES/shell/lib/psv.sh" "$fixture_dir/shell/lib/psv.sh"
export DOTFILES="$fixture_dir"
fixture_output=$(myenv)
export DOTFILES="$REAL_DOTFILES"
rm -rf "$fixture_dir"

echo "$fixture_output" | grep -qF "zzz-not-a-real-tool"
assert_true $? "fixture entry zzz-not-a-real-tool appears in output"

echo "$fixture_output" | grep -qE "✓ rg |✗ rg |ripgrep"
if [ $? -eq 0 ]; then real_tool_absent=1; else real_tool_absent=0; fi
assert_true "$real_tool_absent" "real catalog entry (rg) does not leak into fixture output"

test_case "myenv is self-locating: works with DOTFILES unset, sourced through a symlink"
scratch="$(mktemp -d)"
mkdir -p "$scratch/config/shell"
# MSYS=winsymlinks:nativestrict makes `ln -s` create a real symlink under
# Git Bash on Windows (it otherwise silently falls back to a copy); it is a
# no-op everywhere else.
MSYS=winsymlinks:nativestrict ln -s "$DOTFILES/shell/functions.sh" "$scratch/config/shell/functions.sh"
unset_output=$(env -u DOTFILES bash -c "source '$scratch/config/shell/functions.sh'; myenv" 2>&1)
unset_status=$?
rm -rf "$scratch"
assert_true "$unset_status" "myenv exits 0 with DOTFILES unset (real install has no DOTFILES set)"
echo "$unset_output" | grep -q "My Environment"
assert_true $? "myenv produced real catalog output, not a 'catalog not found' error"

test_summary
