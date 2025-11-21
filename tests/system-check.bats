#!/usr/bin/env bats

# Integration + unit tests for system-check.sh using Bats.
# Helper functions are sourced by extracting the pre-main portion of the script.

setup_file() {
  PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$PROJECT_ROOT/system-check.sh"
  REAL_DATE_BIN="$(command -v date)"
  HELPERS_SNIPPET="$(mktemp)"
  awk '/^# Print welcome banner/ {exit} {print}' "$SCRIPT" > "$HELPERS_SNIPPET"
}

teardown_file() {
  rm -f "$HELPERS_SNIPPET"
}

setup() {
  ORIGINAL_PATH="$PATH"
  STUB_DIR="$(mktemp -d)"
  PATH="$STUB_DIR:$ORIGINAL_PATH"
  TEST_DIRS=()
}

teardown() {
  PATH="$ORIGINAL_PATH"
  rm -rf "$STUB_DIR"
  for dir in "${TEST_DIRS[@]}"; do
    rm -rf "$dir"
  done
}

register_tmpdir() {
  TEST_DIRS+=("$1")
}

strip_ansi_text() {
  python3 - <<'PY'
import re, sys
sys.stdout.write(re.sub(r'\x1B\[[0-9;]*m', '', sys.stdin.read()))
PY
}

stub_date_fixed() {
  cat <<EOF > "$STUB_DIR/date"
#!/bin/bash
if [[ "\$1" == "+%Y-%m-%d %H:%M:%S" ]]; then
  echo "2024-01-01 12:00:00"
else
  "$REAL_DATE_BIN" "\$@"
fi
EOF
  chmod +x "$STUB_DIR/date"
}

stub_df() {
  local root_percent="$1"
  local disk_percent="${2:-50}"
  cat <<EOF > "$STUB_DIR/df"
#!/bin/bash
if [[ "\$1" == "-P" ]]; then
  cat <<'DFROOT'
Filesystem 1024-blocks Used Available Capacity Mounted on
/dev/root 100000 95000 5000 ROOTP% /
DFROOT
  exit 0
fi

args=("\$@")
cat <<'DFLIST'
Filesystem Size Used Avail Use%
/dev/sda1 100G 50G 50G DISKP%
/dev/sdb1 200G 100G 100G DISKP%
DFLIST
EOF
  sed -i "s/ROOTP/$root_percent/g" "$STUB_DIR/df"
  sed -i "s/DISKP/$disk_percent/g" "$STUB_DIR/df"
  chmod +x "$STUB_DIR/df"
}

stub_find_permission_denied() {
  cat <<'EOF' > "$STUB_DIR/find"
#!/bin/bash
echo "find: Permission denied" >&2
exit 1
EOF
  chmod +x "$STUB_DIR/find"
}

create_sample_files() {
  local dir
  dir="$(mktemp -d)"
  register_tmpdir "$dir"
  dd if=/dev/zero of="$dir/big.bin" bs=1024 count=6 >/dev/null 2>&1
  dd if=/dev/zero of="$dir/medium.bin" bs=1024 count=4 >/dev/null 2>&1
  dd if=/dev/zero of="$dir/small.bin" bs=1024 count=1 >/dev/null 2>&1
  echo "$dir"
}

assert_contains() {
  local needle="$1"
  local haystack="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "Expected output to contain: $needle"
    echo "Actual output:"
    echo "$haystack"
    return 1
  fi
}

@test "repeat_char repeats characters the requested number of times" {
  run bash -c "source '$HELPERS_SNIPPET'; repeat_char '*' 5"
  [ "$status" -eq 0 ]
  [ "$output" = "*****" ]
}

@test "repeat_char returns an empty string when count is non-positive" {
  run bash -c "source '$HELPERS_SNIPPET'; repeat_char '#' 0"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "human_readable_kib renders decimal precision correctly" {
  run bash -c "source '$HELPERS_SNIPPET'; human_readable_kib 1536"
  [ "$status" -eq 0 ]
  [ "$output" = "1.5 MiB" ]
}

@test "human_readable_kib clamps negative values to zero kilobytes" {
  run bash -c "source '$HELPERS_SNIPPET'; human_readable_kib -512"
  [ "$status" -eq 0 ]
  [ "$output" = "0 KiB" ]
}

@test "progress_bar scales to width and colorizes critical usage" {
  run bash -c "source '$HELPERS_SNIPPET'; progress_bar 50"
  [ "$status" -eq 0 ]
  plain=$(printf '%s' "$output" | strip_ansi_text)
  local filled empty expected
  filled=$(printf '█%.0s' {1..15})
  empty=$(printf '░%.0s' {1..15})
  expected="$filled$empty"
  [ "$plain" = "$expected" ]

  run bash -c "source '$HELPERS_SNIPPET'; progress_bar 95"
  [ "$status" -eq 0 ]
  [[ "$output" == $'\033[0;31m'* ]]
}

@test "script prints disk, memory, and file sections using stubbed commands" {
  stub_df 40 55
  stub_date_fixed
  workdir="$(create_sample_files)"
  run bash -c "cd '$workdir' && '$SCRIPT'"
  [ "$status" -eq 0 ]
  plain=$(printf '%s' "$output" | strip_ansi_text)
  assert_contains "SYSTEM HEALTH CHECK" "$plain"
  assert_contains "DISK SPACE" "$plain"
  assert_contains "/dev/sda1" "$plain"
  assert_contains "TOP 5 LARGEST FILES" "$plain"
  assert_contains "big.bin" "$plain"
  assert_contains "Summary" "$plain"
}

@test "script reports when no files are found in the current directory" {
  stub_df 45 45
  stub_date_fixed
  empty_dir="$(mktemp -d)"
  register_tmpdir "$empty_dir"
  run bash -c "cd '$empty_dir' && '$SCRIPT'"
  [ "$status" -eq 0 ]
  plain=$(printf '%s' "$output" | strip_ansi_text)
  assert_contains "No files found in current directory" "$plain"
}

@test "script handles permission-denied errors from find gracefully" {
  stub_df 50 50
  stub_date_fixed
  stub_find_permission_denied
  dir_with_files="$(mktemp -d)"
  register_tmpdir "$dir_with_files"
  touch "$dir_with_files/some-file"
  run bash -c "cd '$dir_with_files' && '$SCRIPT'"
  [ "$status" -eq 0 ]
  plain=$(printf '%s' "$output" | strip_ansi_text)
  assert_contains "No files found in current directory" "$plain"
}

@test "summary warns when root filesystem usage exceeds 90 percent" {
  stub_df 95 85
  stub_date_fixed
  workdir="$(create_sample_files)"
  run bash -c "cd '$workdir' && '$SCRIPT'"
  [ "$status" -eq 0 ]
  plain=$(printf '%s' "$output" | strip_ansi_text)
  assert_contains "WARNING - Low Disk Space" "$plain"
}
