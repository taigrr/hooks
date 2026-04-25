#!/usr/bin/env bash
# Install git hooks globally via core.hooksPath.
# Usage: ./install.sh [--template] [--check]
#   --template  Use init.templateDir instead (only affects new repos)
#   --check     Show current hooks configuration without changing anything

set -euo pipefail

hook_dir="$(cd "$(dirname "$0")" && pwd)"
use_template=false
check_only=false

usage() {
	cat <<EOF
Usage: ./install.sh [--template] [--check] [--help]

Options:
  --template  Use init.templateDir instead of core.hooksPath
  --check     Show current hooks configuration without changing anything
  --help      Show this help text
EOF
}

for arg in "$@"; do
	case "$arg" in
		--template)
			use_template=true
			;;
		--check)
			check_only=true
			;;
		--help|-h)
			usage
			exit 0
			;;
		*)
			echo "Unknown option: $arg" >&2
			usage >&2
			exit 1
			;;
	esac
done

if [ "$check_only" = true ]; then
	hooks_path=$(git config --global --get core.hooksPath 2>/dev/null || true)
	template_dir=$(git config --global --get init.templateDir 2>/dev/null || true)
	if [ -n "$hooks_path" ]; then
		echo "core.hooksPath = $hooks_path"
		if [ "$hooks_path" = "$hook_dir" ]; then
			echo "  (points to this directory)"
		else
			echo "  (points elsewhere — not this directory)"
		fi
	fi
	if [ -n "$template_dir" ]; then
		echo "init.templateDir = $template_dir"
		if [ "$template_dir" = "$hook_dir" ]; then
			echo "  (points to this directory)"
		else
			echo "  (points elsewhere — not this directory)"
		fi
	fi
	if [ -z "$hooks_path" ] && [ -z "$template_dir" ]; then
		echo "No global hooks configuration found."
	fi
	exit 0
fi

if [ "$use_template" = true ]; then
	git config --global init.templateDir "$hook_dir"
	echo "Installed: init.templateDir set to $hook_dir"
	echo "New repos created with git init/clone will copy these hooks."
else
	git config --global core.hooksPath "$hook_dir"
	echo "Installed: core.hooksPath set to $hook_dir"
	echo "All repos will use hooks from $hook_dir."
fi
