#!/usr/bin/env bash
# Remove global git hooks configuration set by install.sh.

set -euo pipefail

found=false

if git config --global --get core.hooksPath > /dev/null 2>&1; then
	git config --global --unset core.hooksPath
	echo "Removed core.hooksPath"
	found=true
fi

if git config --global --get init.templateDir > /dev/null 2>&1; then
	git config --global --unset init.templateDir
	echo "Removed init.templateDir"
	found=true
fi

if [ "$found" = false ]; then
	echo "No global hooks configuration found."
	exit 0
fi

echo "Global hooks configuration cleared."
