#!/bin/bash
set -euo pipefail

# Check whether a package is installed.
# The package is given as the first argument.
# Use like so:
# if ! "${toolPath}/package-check.sh" docker; then
#     echo "docker not installed"
#     exit 0
# fi

REQUIRED_PKG=$1
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' "$REQUIRED_PKG" 2>/dev/null | grep "install ok installed") || true
if [ "" = "$PKG_OK" ]; then
	exit 1
fi
