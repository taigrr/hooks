#!/usr/bin/env bash
# Install git hooks globally via core.hooksPath.
# Usage: ./install.sh [--template]
#   --template  Use init.templateDir instead (only affects new repos)

set -euo pipefail

hook_dir="$(cd "$(dirname "$0")" && pwd)"

if [ "${1:-}" = "--template" ]; then
	git config --global init.templateDir "$hook_dir"
	echo "Installed: init.templateDir set to $hook_dir"
	echo "New repos created with git init/clone will copy these hooks."
else
	git config --global core.hooksPath "$hook_dir"
	echo "Installed: core.hooksPath set to $hook_dir"
	echo "All repos will use hooks from $hook_dir."
fi
