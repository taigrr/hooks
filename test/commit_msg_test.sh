#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
commit_msg_hook="$repo_root/commit-msg"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

run_hook() {
	local expected_status="$1"
	local message="$2"
	local msg_file="$tmpdir/message"

	printf '%s\n' "$message" > "$msg_file"

	set +e
	output=$(bash "$commit_msg_hook" "$msg_file" 2>&1)
	status=$?
	set -e

	if [ "$status" -ne "$expected_status" ]; then
		echo "expected exit $expected_status for message: $message" >&2
		echo "got exit $status" >&2
		echo "$output" >&2
		exit 1
	fi
}

assert_rejected() {
	local message="$1"

	run_hook 1 "$message"
	if ! printf '%s' "$output" | grep -Fq "ERROR: Commit message does not follow Conventional Commits format."; then
		echo "expected rejection output for message: $message" >&2
		echo "$output" >&2
		exit 1
	fi
}

run_hook 0 "feat: add checkout hook"
run_hook 0 "fix(shell/hooks): preserve lfs args"
run_hook 0 "feat(api)!: change hook contract"
run_hook 0 "Merge pull request #6 from taigrr/cd/clear-conflicting-hook-config"
run_hook 0 "fixup! fix(shell): preserve lfs args"
run_hook 0 "squash! test(shell): add regression coverage"

assert_rejected "update hook behavior"
assert_rejected "feature: add checkout hook"
assert_rejected "fix(shell):"

echo "commit-msg regression tests passed"
