#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
install_script="$repo_root/install.sh"
uninstall_script="$repo_root/uninstall.sh"
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

assert_set_to() {
	local key="$1"
	local expected="$2"
	local actual
	actual=$(GIT_CONFIG_GLOBAL="$global_config" git config --global --get "$key")
	if [ "$actual" != "$expected" ]; then
		echo "expected $key to be $expected, got $actual" >&2
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
assert_unset core.hooksPath

output=$(run 0 bash "$install_script")
assert_contains "$output" "Installed: core.hooksPath set to $repo_root"
assert_contains "$output" "Cleared global init.templateDir (it pointed to this directory)."
hooks_path=$(GIT_CONFIG_GLOBAL="$global_config" git config --global --get core.hooksPath)
[ "$hooks_path" = "$repo_root" ]
assert_unset init.templateDir

output=$(run 0 bash "$install_script" --template)
assert_contains "$output" "Installed: init.templateDir set to $repo_root"
assert_contains "$output" "Cleared global core.hooksPath (it pointed to this directory)."
template_dir=$(GIT_CONFIG_GLOBAL="$global_config" git config --global --get init.templateDir)
[ "$template_dir" = "$repo_root" ]
assert_unset core.hooksPath

output=$(run 1 bash "$install_script" --bogus)
assert_contains "$output" "Unknown option: --bogus"

output=$(run 0 bash "$uninstall_script")
assert_contains "$output" "Removed init.templateDir"
assert_contains "$output" "Global hooks configuration cleared."
assert_unset init.templateDir

GIT_CONFIG_GLOBAL="$global_config" git config --global core.hooksPath /tmp/other-hooks
GIT_CONFIG_GLOBAL="$global_config" git config --global init.templateDir /tmp/other-template
output=$(run 0 bash "$uninstall_script")
assert_contains "$output" "Left core.hooksPath unchanged: /tmp/other-hooks"
assert_contains "$output" "Left init.templateDir unchanged: /tmp/other-template"
assert_contains "$output" "No global hooks configuration found for $repo_root."
assert_set_to core.hooksPath /tmp/other-hooks
assert_set_to init.templateDir /tmp/other-template

# Safety: a foreign core.hooksPath (not this dir) must be preserved, not clobbered.
run 0 bash "$uninstall_script" >/dev/null
GIT_CONFIG_GLOBAL="$global_config" git config --global core.hooksPath /tmp/other-hooks
output=$(run 0 bash "$install_script" --template)
assert_contains "$output" "WARNING: global core.hooksPath = /tmp/other-hooks is set and may conflict."
assert_set_to core.hooksPath /tmp/other-hooks
assert_set_to init.templateDir "$repo_root"
run 0 bash "$uninstall_script" >/dev/null
GIT_CONFIG_GLOBAL="$global_config" git config --global --unset core.hooksPath >/dev/null 2>&1 || true

# Safety: overwriting a foreign value of the SAME mechanism warns (but proceeds).
GIT_CONFIG_GLOBAL="$global_config" git config --global core.hooksPath /tmp/other-hooks
output=$(run 0 bash "$install_script")
assert_contains "$output" "WARNING: overwriting existing global core.hooksPath = /tmp/other-hooks"
assert_set_to core.hooksPath "$repo_root"
run 0 bash "$uninstall_script" >/dev/null

output=$(run 0 bash "$install_script" --help)
assert_contains "$output" "Usage: ./install.sh"

echo "install/uninstall regression tests passed"
