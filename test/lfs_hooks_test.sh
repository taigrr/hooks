#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

assert_empty() {
	local value="$1"
	local label="$2"
	if [ -n "$value" ]; then
		echo "expected empty $label, got:" >&2
		echo "$value" >&2
		exit 1
	fi
}

run_without_git_lfs() {
	local hook="$1"
	local output status

	set +e
	output=$(PATH="$tmpdir/bin" sh "$repo_root/$hook" 2>&1)
	status=$?
	set -e

	if [ "$status" -ne 0 ]; then
		echo "expected $hook to exit 0 without git-lfs, got $status" >&2
		echo "$output" >&2
		exit 1
	fi
	assert_empty "$output" "$hook output"
}

run_with_git_lfs() {
	local hook="$1"
	local status

	: >"$tmpdir/lfs.log"
	set +e
	PATH="$lfsbin" sh "$repo_root/$hook" alpha beta >/dev/null 2>&1
	status=$?
	set -e

	if [ "$status" -ne 0 ]; then
		echo "expected $hook to exit 0 with git-lfs present, got $status" >&2
		exit 1
	fi
	local logged
	logged="$(cat "$tmpdir/lfs.log")"
	local expected="$hook alpha beta"
	if [ "$logged" != "$expected" ]; then
		echo "expected $hook to delegate '$expected', got '$logged'" >&2
		exit 1
	fi
}

mkdir -p "$tmpdir/bin"
ln -s "$(command -v sh)" "$tmpdir/bin/sh"
ln -s "$(command -v git)" "$tmpdir/bin/git"
if command -v wc >/dev/null 2>&1; then
	ln -s "$(command -v wc)" "$tmpdir/bin/wc"
fi

run_without_git_lfs post-checkout
run_without_git_lfs post-commit
run_without_git_lfs post-merge
run_without_git_lfs pre-push

# git-lfs-present path: stub a fake git-lfs so `git lfs <sub>` delegates to it,
# and assert the hook forwards the subcommand and arguments.
lfsbin="$tmpdir/lfsbin"
mkdir -p "$lfsbin"
ln -s "$(command -v sh)" "$lfsbin/sh"
ln -s "$(command -v git)" "$lfsbin/git"
if command -v wc >/dev/null 2>&1; then
	ln -s "$(command -v wc)" "$lfsbin/wc"
fi
# Fake git-lfs: `track` reports a tracked pattern (so pre-push's wc -l gate
# passes); every other subcommand records its full delegated arg list.
cat >"$lfsbin/git-lfs" <<EOF
#!/bin/sh
if [ "\$1" = track ]; then
	echo '*.bin filter=lfs'
	exit 0
fi
printf '%s' "\$*" >"$tmpdir/lfs.log"
EOF
chmod +x "$lfsbin/git-lfs"

run_with_git_lfs post-checkout
run_with_git_lfs post-commit
run_with_git_lfs post-merge
run_with_git_lfs pre-push

echo "lfs hook regression tests passed"
