#!/bin/sh
# Copyright (C) 2025-2026 ukriu (Contact: contact@ukriu.com)
# Tanzanite variant structure by @noticesa
# Read LICENSE_NOTICE.txt for further info.
MODDIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
. "$MODDIR/common/utils.sh"

restore_deviceLevelList
rm -rf "$RESDIR/xml"
#settings put secure background_blur_enable 0
exit 0

# EOF
