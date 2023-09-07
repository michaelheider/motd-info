#!/bin/bash
set -euo pipefail

# Print information on partition usage.
# Run it to see what it looks like.

# config
PARTITION_WARN=80 # %
FILTER=''         # excluded targets separated by |

TOOL_PATH=$(realpath "$(dirname "$0")/../tools")
# shellcheck source-path=../tools
source "${TOOL_PATH}/colors.sh"

if [ -n "$FILTER" ]; then
    # prepend '|' to put into filter below
    FILTER="|$FILTER"
fi
mapfile -t partitions < <(df -hT | grep -vE "tmpfs|vfat${FILTER}" | tail -n+2 | sort -k7)
out=" |Size|Use%\n"
for line in "${partitions[@]}"; do
    IFS=" " read -r device fstype size used available percent target <<<"${line}"
    percentnb=${percent//%/}
    percent=$(colorIf "${percentnb}" '<' "${PARTITION_WARN}" '%')
    out+="${target}|${size}|${percent}\n"
done

echo 'partitions usage:'
echo -e "${out}" | column -ts'|' -R "2,3" | sed 's,^,  ,'
