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

echo "lfs hook regression tests passed"
