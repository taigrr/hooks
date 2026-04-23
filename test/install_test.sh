#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
install_script="$repo_root/install.sh"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

export HOME="$tmpdir/home"
mkdir -p "$HOME"

global_config="$HOME/.gitconfig"

run() {
	local expected_status="$1"
	shift
	set +e
	output=$(GIT_CONFIG_GLOBAL="$global_config" "$@" 2>&1)
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

assert_unset() {
	local key="$1"
	if GIT_CONFIG_GLOBAL="$global_config" git config --global --get "$key" >/dev/null 2>&1; then
		echo "expected $key to be unset" >&2
		exit 1
	fi
}

output=$(run 0 bash "$install_script" --check)
assert_contains "$output" "No global hooks configuration found."

output=$(run 0 bash "$install_script" --template --check)
assert_contains "$output" "No global hooks configuration found."
assert_unset core.hooksPath
assert_unset init.templateDir

output=$(run 0 bash "$install_script" --template)
assert_contains "$output" "Installed: init.templateDir set to $repo_root"
template_dir=$(GIT_CONFIG_GLOBAL="$global_config" git config --global --get init.templateDir)
[ "$template_dir" = "$repo_root" ]

output=$(run 1 bash "$install_script" --bogus)
assert_contains "$output" "Unknown option: --bogus"

output=$(run 0 bash "$install_script" --help)
assert_contains "$output" "Usage: ./install.sh"

echo "install.sh regression tests passed"
