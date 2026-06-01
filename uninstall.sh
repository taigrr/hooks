#!/usr/bin/env bash
# Remove global git hooks configuration set by install.sh.

set -euo pipefail

hook_dir="$(cd "$(dirname "$0")" && pwd)"
found=false

hooks_path=$(git config --global --get core.hooksPath 2>/dev/null || true)
if [ -n "$hooks_path" ]; then
	if [ "$hooks_path" = "$hook_dir" ]; then
		git config --global --unset core.hooksPath
		echo "Removed core.hooksPath"
		found=true
	else
		echo "Left core.hooksPath unchanged: $hooks_path"
	fi
fi

template_dir=$(git config --global --get init.templateDir 2>/dev/null || true)
if [ -n "$template_dir" ]; then
	if [ "$template_dir" = "$hook_dir" ]; then
		git config --global --unset init.templateDir
		echo "Removed init.templateDir"
		found=true
	else
		echo "Left init.templateDir unchanged: $template_dir"
	fi
fi

if [ "$found" = false ]; then
	echo "No global hooks configuration found for $hook_dir."
	exit 0
fi

echo "Global hooks configuration cleared."
