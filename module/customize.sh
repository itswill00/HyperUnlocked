#!/bin/sh
# Copyright (C) 2025-2026 ukriu (Contact: contact@ukriu.com)
# Tanzanite variant structure by @noticesa
# Read LICENSE_NOTICE.txt for further info.
if ! $BOOTMODE; then
    ui_print "*********************************************************"
    ui_print "Installing from recovery is not recommended!"
    ui_print "The installation will continue, but it is recommended to click the action button in the manager to finish the setup!"
    ui_print "*********************************************************"
fi

export MODPATH
. $MODPATH/common/utils.sh
. $MODPATH/common/apply.sh

check_supported
check_tanzanite
disable_incompatible_modules
migrate_legacy_state
save_deviceLevelList
apply_tanzanite_defaults
xml_init
update_desc
warning
credits

# EOF
