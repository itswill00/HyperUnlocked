#!/bin/sh
# Copyright (C) 2025-2026 ukriu (Contact: contact@ukriu.com)
# Tanzanite variant structure & defaults by @noticesa
# Read LICENSE_NOTICE.txt for further info.

PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH
RESDIR=/data/adb/Tanzanite-HyperUnlocked
OLDRESDIR=/data/adb/HyperUnlocked
mkdir -p $RESDIR
DEVICE_CODENAME=$(getprop ro.product.device)
CUR_DEVICE_LEVEL_LIST=$(su -c "settings get system deviceLevelList")
SAV_DEVICE_LEVEL_LIST=$(cat "$RESDIR/default_deviceLevelList.txt")
HIGH_END="v:1,c:3,g:3"
MODDIR="${MODPATH:-/data/adb/modules/Tanzanite-HyperUnlocked}"

if ls /system/product/etc/device_features/*.xml >/dev/null 2>&1; then
    DEFAULT_XMLDIR=/system/product/etc/device_features
elif ls /system/etc/device_features/*.xml >/dev/null 2>&1; then
    DEFAULT_XMLDIR=/system/etc/device_features
elif ls /system/system/etc/device_features/*.xml >/dev/null 2>&1; then
    DEFAULT_XMLDIR=/system/system/etc/device_features
fi

XML_DIR="${MODDIR}${DEFAULT_XMLDIR}"

log() {
    echo "[-] $*"
}
warn() {
    echo "[!] $*"
}

check_supported() {
    #Check for ximi rom
    if [ -n "$(getprop ro.mi.os.version.name)" ] || [ -n "$(getprop ro.miui.ui.version.code)" ]; then
        log "Mi ROM identified."
    else
        warn "This ROM is not supported. Please use an OS made by Xiaomi (HyperOS/MIUI)."
        warn "If you think this is a mistake.. then create an issue at:"
        warn "https://github.com/itswill00/HyperUnlocked"
        exit 1
    fi

    if [ -d "$DEFAULT_XMLDIR" ] && find -L "$DEFAULT_XMLDIR" -maxdepth 1 -type f -name "*.xml" -print -quit 2>/dev/null | grep -q .; then
        log "Your device is supported."
    else
        warn "Your device is not fully supported and might lack some features."
        sleep 2
    fi
}

check_tanzanite() {
    # Tanzanite-only variant: warn (not abort) on other codenames so the
    # community build stays safe but still installable for testing.
    if [ "$DEVICE_CODENAME" = "tanzanite" ]; then
        log "Tanzanite identified. Applying tanzanite-only defaults."
    else
        warn "This variant is tuned for tanzanite, detected: $DEVICE_CODENAME."
        warn "Continuing anyway, use WebUI to adjust."
        sleep 2
    fi
}

disable_incompatible_modules() {
    log "Checking for incompatible modules..."
    found_incompatible=false

    for dir in /data/adb/modules/*; do
        if [ -d "$dir" ]; then
            module_name=$(basename "$dir")
            [ "$module_name" = "Tanzanite-HyperUnlocked" ] && continue
            if [ -f "${dir}${DEFAULT_XMLDIR}/${DEVICE_CODENAME}.xml" ]; then
                found_incompatible=true
                log "Incompatible module: \`$module_name\`"
                if touch "$dir/disable"; then
                    log "Disabled: \`$module_name\`"
                else
                    log "Failed to disable \`$module_name\`"
                    log "Please uninstall the module to prevent issues."
                    sleep 0.3
                fi
            fi
        fi
    done

    if [ "$found_incompatible" = false ]; then
        log "No incompatible modules found."
    else
        log "Please uninstall the disabled modules later!"
    fi
}

save_deviceLevelList() {
    if [ -s "$RESDIR/default_deviceLevelList.txt" ]; then
        log "The deviceLevelList backup already exists. ($(cat $RESDIR/default_deviceLevelList.txt))"
        return
    fi

    if [ -z "$CUR_DEVICE_LEVEL_LIST" ] || [ "$CUR_DEVICE_LEVEL_LIST" = "null" ]; then
        log "Failed to retrieve deviceLevelList."
        log "Continuing without backup value."
    else
        echo "$CUR_DEVICE_LEVEL_LIST" > "$RESDIR/default_deviceLevelList.txt"
        log "Default deviceLevelList: $(cat "$RESDIR/default_deviceLevelList.txt")"
    fi
}

migrate_legacy_state() {
    # One-way migration from previous HyperUnlocked installs: carry over
    # the true-stock deviceLevelList backup and XML backup so restore
    # and re-edits keep working under the new state dir.
    for entry in default_deviceLevelList.txt bakxml; do
        if [ -e "$OLDRESDIR/$entry" ] && [ ! -e "$RESDIR/$entry" ]; then
            cp -r "$OLDRESDIR/$entry" "$RESDIR/$entry"
            log "Migrated legacy state: $entry"
        fi
    done
}

restore_deviceLevelList() {
    if [ -f "$RESDIR/default_deviceLevelList.txt" ]; then
        if su -c "settings put system deviceLevelList $SAV_DEVICE_LEVEL_LIST"; then
            log "Restored deviceLevelList: $SAV_DEVICE_LEVEL_LIST"
        else
            log "Failed to restore deviceLevelList."
        fi
    else
        log "No deviceLevelList backup found."
    fi
}

set_highend() {
    log "New deviceLevelList value: $HIGH_END"
    if su -c "settings put system deviceLevelList $HIGH_END"; then
        log "Spoofed as high-end device."
    else
        log "Failed to spoof as a high-end device."
    fi
}

add_qs_tiles() {
    case "$1" in
        all)
            REQ="reduce_brightness,saver,taplus_tile,custom_GMS,mictoggle,cameratoggle,custom(com.miui.securitycenter/com.miui.permcenter.settings.InvisibleModeTileService)"
            ;;
        "")
            REQ="reduce_brightness,saver,taplus_tile,custom_GMS,mictoggle,cameratoggle,custom(com.miui.securitycenter/com.miui.permcenter.settings.InvisibleModeTileService)"
            ;;
        custom)
            REQ="$2"
            ;;
        *)
            log "add_qs_tiles: expected 'all' or 'custom <tile>'"
            return 1
            ;;
    esac
    CURRENT="$(settings get secure sysui_qs_tiles)"
    UPDATED="$CURRENT"
    MISSING=""
    for T in ${REQ//,/ }; do
        echo "$CURRENT" | grep -q "$T" || MISSING="$MISSING,$T"
    done
    [ -z "$MISSING" ] && {
        log "Extra QS tiles already present."
        return
    }
    MISSING="${MISSING#,}"
    if echo "$CURRENT" | grep -q ",edit"; then
        UPDATED="$(echo "$CURRENT" | sed "s|,edit|,$MISSING,edit|")"
    else
        UPDATED="$CURRENT,$MISSING"
    fi
    settings put secure sysui_qs_tiles "$UPDATED"
    log "Added unavailable QS tiles."
}

remove_ssblur() {
    if [ -f "$MODDIR/system/product/overlay/HyperUnlocked-screenshot-blur.apk" ]; then
        cp $MODDIR/system/product/overlay/HyperUnlocked-screenshot-blur.apk $RESDIR/
        rm $MODDIR/system/product/overlay/HyperUnlocked-screenshot-blur.apk
    fi
}

add_ssblur() {
    if [ ! -f "$MODDIR/system/product/overlay/HyperUnlocked-screenshot-blur.apk" ]; then
        cp "$RESDIR/HyperUnlocked-screenshot-blur.apk" "$MODDIR/system/product/overlay/"
    fi
    # Disable advanced textures: screenshot blur leaves visual artifacts otherwise.
    settings put secure background_blur_enable 0
}

set_ssblur() {
    # Unified screenshot-blur switch (overlay file op, not a prop).
    if [ "$1" = "true" ]; then
        add_ssblur
    else
        remove_ssblur
    fi
}

remove_dead_overlays() {
    # Drop overlay APKs this variant no longer ships (cc-icons was a
    # byte-identical duplicate of the systemui overlay; thememanager has
    # no idmap on tanzanite/HOS2). Needed on updates where the manager
    # extracts over the old module dir instead of wiping it.
    for apk in HyperUnlocked-cc-icons.apk HyperUnlocked-com.android.thememanager.apk; do
        if [ -f "$MODDIR/system/product/overlay/$apk" ]; then
            rm -f "$MODDIR/system/product/overlay/$apk"
            log "Removed dead overlay: $apk"
        fi
    done
}

write_props() {
    local prop_file="$1"
    local group="$2"
    local source_file="${MODDIR}/common/all.prop"

    # extract lines between start and stop markers
    awk "/#\\\$start_${group}/,/#\\\$end_${group}/" "$source_file" >> "$prop_file"
    log "Written props '$group' to '$prop_file'"
}

apply_props() {
    PROPFILE="${1:-$MODDIR/system.prop}"
    [ -f "$PROPFILE" ] || return 1

    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ""|\#*)
                continue
                ;;
        esac
        resetprop -n -p "${line%%=*}" "${line#*=}"
    done < "$PROPFILE"
}

define_props() {
    head -n 3 ${MODDIR}/common/all.prop > ${MODDIR}/system.prop
    write_props "${MODDIR}/system.prop" "basic"
    write_props "${MODDIR}/system.prop" "experimental"
    if [ "$CHOICE_HE" = true ]; then
        write_props "${MODDIR}/system.prop" "highend"
    fi
    if [ "$CHOICE_BLUR" = true ]; then
        write_props "${MODDIR}/system.prop" "bluron"
    else
        write_props "${MODDIR}/system.prop" "bluroff"
    fi
    if [ "$CHOICE_LEICA" = true ]; then
        write_props "${MODDIR}/system.prop" "leica"
        pm clear com.android.camera
    fi
    if [ "$CHOICE_ISLAND" = true ]; then
        write_props "${MODDIR}/system.prop" "islandon"
    else
        write_props "${MODDIR}/system.prop" "islandoff"
    fi
}

# Rebrand note: upstream anti-tamper was removed with the author's
# permission (credit kept in module.prop, credits() and README).

xml_init() {
    #backup default xml files
    if [ ! -d "$RESDIR/xml" ]; then
        mkdir -p $RESDIR/bakxml
        su -c "cp -r ${DEFAULT_XMLDIR}/* $RESDIR/bakxml/"
    fi
    # remove old edited xmls
    rm -rf $RESDIR/xml
    log "Creating custom XML"
    mkdir -p $RESDIR/xml
    # use def xml for every new edit if available
    if [ -d "$RESDIR/bakxml" ]; then
        su -c "cp -r $RESDIR/bakxml/* $RESDIR/xml/"
    else
        su -c "cp -r ${DEFAULT_XMLDIR}/* $RESDIR/xml/"
    fi
    . "$MODDIR/common/xml.sh"

    find "$RESDIR/xml" -type f -name "*.xml" | while read -r xml_file; do
        # remove comments and empty lines
        busybox sed -i -e '/\$<!--/d' -e '/-->\$/d' -e '/<!--.*-->/d' -e '/^[[:space:]]*$/d' $xml_file
        update_file "$xml_file"
    done

    mkdir -p $XML_DIR/
    su -c "cp -r ${RESDIR}/xml/* ${XML_DIR}/"
}

update_file() {
    xml_file="$1"
    warn "editing: $xml_file"
    touch $RESDIR/tmpsed.txt
    tmp_sed="$RESDIR/tmpsed.txt"
    changes=0

    # get default indent for adding new props
    default_indent=$(busybox grep -E "^[[:space:]]*<bool[[:space:]]" "$xml_file" | busybox sed -E 's/^([[:space:]]*).*/\1/' | head -n 1)
    [ -z "$default_indent" ] && default_indent="    "
    # escape for sed insert
    default_indent=$(printf '%s' "$default_indent" | busybox sed 's/ /\\ /g; s/\t/\\t/g')

    # Applies each prop list below; kept as explicit sequential passes on purpose.
    process_prop_list "$xml_file" "$tmp_sed" "true"  "$bools_true"  "$default_indent" "bool"
    process_prop_list "$xml_file" "$tmp_sed" "true" "$aod_bools_true" "$default_indent" "bool"
    process_prop_list "$xml_file" "$tmp_sed" "true" "$cam_bools_true" "$default_indent" "bool"
    process_prop_list "$xml_file" "$tmp_sed" "true" "$gal_bools_true" "$default_indent" "bool"
    # NOTE: $bools_false is intentionally empty for tanzanite (stock
    # Redmi branding kept OTA-safe), so no false-pass is needed here.
    process_prop_list "$xml_file" "$tmp_sed" "false" "$aod_bools_false" "$default_indent" "bool"
    process_prop_list "$xml_file" "$tmp_sed" "false" "$cam_bools_false" "$default_indent" "bool"
    process_prop_list "$xml_file" "$tmp_sed" "100" "$integer_100" "$default_indent" "integer"
    process_prop_list "$xml_file" "$tmp_sed" "1" "$integer_1" "$default_indent" "integer"
    process_prop_list "$xml_file" "$tmp_sed" "game_enhance_fisr" "$string_game_enhance_fisr" "$default_indent" "string"
    set_fps "$xml_file" "$tmp_sed" "$supported_fps" "$default_indent"

    if [ "$changes" -gt 0 ]; then
        busybox sed -i -f "$tmp_sed" "$xml_file"
        log "$changes new changes applied."
    else
        log "no XML changes needed."
    fi

    rm -f "$tmp_sed"
}

process_prop_list() {
    xml_file="$1"
    tmp_sed="$2"
    value="$3"
    props="$4"
    default_indent="$5"
    value_type="$6"

    for prop in $props; do
        if busybox grep -Eq "^[[:space:]]*<$value_type[[:space:]]+name=['\"]$prop['\"][^>]*>" "$xml_file"; then
            current_val=$(busybox grep -E "^[[:space:]]*<$value_type[[:space:]]+name=['\"]$prop['\"][^>]*>" "$xml_file" | busybox sed -E "s/.*>([[:space:]]*[a-zA-Z0-9_]+[[:space:]]*)<\/[[:space:]]*$value_type>.*/\1/" | busybox tr -d '[:space:]')
            if [ "$current_val" != "$value" ]; then
                echo "s|^[[:space:]]*<$value_type[[:space:]]\{1,\}name=['\"]$prop['\"][^>]*>.*</$value_type>|${default_indent}<$value_type name=\"$prop\">$value</$value_type>|" >> "$tmp_sed"
                changes=$((changes+1))
            #    log "DEBUG: set $prop to $value"
            #else
            #    log "DEBUG: $prop already $value"
            fi
        else
            # add missing prop before features
            echo "/<\/features>/i $default_indent<$value_type name=\"$prop\">$value</$value_type>" >> "$tmp_sed"
            changes=$((changes+1))
            #log "DEBUG: added $prop as $value"
        fi
    done
}

set_fps() {
    xml_file="$1"
    tmp_sed="$2"
    fps_list="$3"
    default_indent="$4"

    # find existing fpsList block
    start_line=$(busybox grep -n "<integer-array name=\"fpsList\">" "$xml_file" | busybox cut -d: -f1 | busybox head -n 1)
    if [ -n "$start_line" ]; then
        end_line=$(busybox grep -n "</integer-array>" "$xml_file" | busybox cut -d: -f1 | busybox awk -v s="$start_line" '$1 > s {print; exit}')
    else
        end_line=""
    fi

    # if block exists, extract existing fps and compare sets
    if [ -n "$start_line" ] && [ -n "$end_line" ]; then
        # extract fps list
        existing_list=$(busybox sed -n "${start_line},${end_line}p" "$xml_file" | busybox awk -F'[<>]' '/<item>/{print $3}' | busybox tr -s '\n' ' ' | busybox sed 's/^ *//;s/ *$//')

        #tmp function
        normalize() {
            # one value per line, sort numeric, uniq, join back to space-separated
            echo "$1" | busybox tr ' ' '\n' | busybox awk 'NF' | busybox sort -n | busybox uniq | busybox tr '\n' ' ' | busybox sed 's/ $//'
        }

        existing_norm=$(normalize "$existing_list")
        desired_norm=$(normalize "$fps_list")

        if [ "$existing_norm" = "$desired_norm" ]; then
            # no change required
            return 0
        fi
    fi

    # if this happens then either block is missing or sets differ
    # remove old fps list
    if [ -n "$start_line" ] && [ -n "$end_line" ]; then
        echo "${start_line},${end_line}d" >> "$tmp_sed"
        changes=$((changes+1))
    fi

    # make new fpsList block before features end
    echo "/<\/features>/i ${default_indent}<integer-array name=\"fpsList\">" >> "$tmp_sed"
    for fps in $fps_list; do
        echo "/<\/features>/i ${default_indent}${default_indent}<item>$fps</item>" >> "$tmp_sed"
    done
    echo "/<\/features>/i ${default_indent}</integer-array>" >> "$tmp_sed"
    changes=$((changes+1))
}
# default_indent is threaded through each helper for explicitness.

update_desc() {
    DEFAULT_DESC="High-end Xiaomi features for tanzanite. Based on ukriu's HyperUnlocked."
    if ls "${XML_DIR}"/*.xml >/dev/null 2>&1; then
        xml=" ✅ XML "
    else
        xml=" ❌ XML "
    fi

    if grep -q "highend" "${MODDIR}/system.prop"; then
        high=" ✅ high-end mode "
    else
        high=" ❌ high-end mode "
    fi

    if grep -q "bluron" "${MODDIR}/system.prop"; then
        blur=" ✅ blurs "
        blurs_en=1
    elif grep -q "bluroff" "${MODDIR}/system.prop"; then
        blur=" ❌ blurs "
    else
        blur=" ◻️ blurs "
    fi

    if [ -f "$MODDIR/system/product/overlay/HyperUnlocked-screenshot-blur.apk" ]; then
        ssblur=" ✅ ssblur "
    else
        ssblur=" ◻️ ssblur "
    fi

    NEW_DESC="[${DEVICE_CODENAME}][${xml}][${high}][${blur}] ${DEFAULT_DESC}"
    sed "s/^description=.*/description=${NEW_DESC}/g" $MODDIR/module.prop > $MODDIR/module.prop.tmp
    cat $MODDIR/module.prop.tmp > $MODDIR/module.prop
    rm -f $MODDIR/module.prop.tmp
}

warning() {
    #settings put secure background_blur_enable 1
    log "Turn OFF Advanced Textures to avoid visual glitches/lag (on some devices)."
}

credits() {
    log "HyperUnlocked by ukriu"
    log "Tanzanite variant by @noticesa"
    log "Thank you for using HyperUnlocked."
}

# EOF