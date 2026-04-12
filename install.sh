#!/usr/bin/env bash
# Install git hooks globally via core.hooksPath.
# Usage: ./install.sh [--template] [--check]
#   --template  Use init.templateDir instead (only affects new repos)
#   --check     Show current hooks configuration without changing anything

set -euo pipefail

hook_dir="$(cd "$(dirname "$0")" && pwd)"

if [ "${1:-}" = "--check" ]; then
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

if [ "${1:-}" = "--template" ]; then
	git config --global init.templateDir "$hook_dir"
	echo "Installed: init.templateDir set to $hook_dir"
	echo "New repos created with git init/clone will copy these hooks."
else
	git config --global core.hooksPath "$hook_dir"
	echo "Installed: core.hooksPath set to $hook_dir"
	echo "All repos will use hooks from $hook_dir."
fi
