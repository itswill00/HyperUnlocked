#!/bin/sh
# Copyright (C) 2025-2026 ukriu (Contact: contact@ukriu.com)
# Tanzanite variant structure by @noticesa
# Read LICENSE_NOTICE.txt for further info.
# Re-applies the tanzanite defaults (same as fresh install).
MODDIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
. "$MODDIR/common/utils.sh"
. "$MODDIR/common/apply.sh"

check_supported
check_tanzanite
disable_incompatible_modules
migrate_legacy_state
apply_tanzanite_defaults
xml_init
update_desc
warning
credits

echo
echo "[!!] A reboot is required for some changes."
echo
sleep 1 # let the output stay readable
exit 0

# EOF
