#!/bin/bash
set -euo pipefail
LANG=en_US.UTF-8

# Print information on partition usage.
# Run it to see what it looks like.

# config
partitionWarn=80 # %
filter=''   # excluded targets separated by |

toolPath=$(realpath "$(dirname "$0")/../tools")
source "${toolPath}/colors.sh"

if [ -n "$filter" ]; then
    # prepend '|' to put into filter below
    filter="|$filter"
fi
mapfile -t partitions < <(df -hT | grep -vE "tmpfs|vfat${filter}" | tail -n+2 | sort -k7)
out=" |Size|Use%\n"
for line in "${partitions[@]}"; do
    IFS=" " read -r device fstype size used available percent target <<<"${line}"
    percentnb=${percent//%/}
    percent=$(colorIf "${percentnb}" '<' "${partitionWarn}" '%')
    out+="${target}|${size}|${percent}\n"
done

echo 'partitions usage:'
echo -e "${out}" | column -ts'|' | sed 's,^,  ,'
