#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
pre_commit="$repo_root/pre-commit"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

run() {
	local expected_status="$1"
	shift
	set +e
	output=$("$@" 2>&1)
	status=$?
	set -e
	if [ "$status" -ne "$expected_status" ]; then
		echo "expected exit $expected_status, got $status" >&2
		echo "$output" >&2
		exit 1
	fi
	printf '%s' "$output"
}

assert_contains() {
	local haystack="$1"
	local needle="$2"
	if ! printf '%s' "$haystack" | grep -Fq "$needle"; then
		echo "expected output to contain: $needle" >&2
		echo "$haystack" >&2
		exit 1
	fi
}

cd "$tmpdir"
git init --quiet
git config user.email test@example.com
git config user.name "Test User"

printf 'small\n' > small.txt
git add small.txt
run 0 bash "$pre_commit"
git commit --quiet -m "test: add small file"

no_lfs_bin="$tmpdir/no-lfs-bin"
mkdir -p "$no_lfs_bin"
ln -s "$(command -v bash)" "$no_lfs_bin/bash"
ln -s "$(command -v git)" "$no_lfs_bin/git"
ln -s "$(command -v stat)" "$no_lfs_bin/stat"
run 0 env PATH="$no_lfs_bin" bash "$pre_commit"

rm small.txt
git add small.txt
run 0 bash "$pre_commit"
git commit --quiet -m "test: remove small file"

dd if=/dev/zero of=large.bin bs=1M count=6 status=none
git add large.bin
output=$(run 1 bash "$pre_commit")
assert_contains "$output" "File large.bin is 6MiB"
assert_contains "$output" "Commit too large"

echo "pre-commit regression tests passed"
