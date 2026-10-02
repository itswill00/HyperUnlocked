#!/bin/sh
# Copyright (C) 2025-2026 ukriu (Contact: contact@ukriu.com)
# Tanzanite variant structure & defaults by @noticesa
# Read LICENSE_NOTICE.txt for further info.
#
# Single source of truth for the tanzanite-only install/apply flow.
# Both customize.sh (install) and action.sh (manager Action button)
# funnel through apply_tanzanite_defaults() so defaults can't drift.
# Fine-grained tuning stays in WebUI (common/webui.sh is NOT used here;
# webui.sh lives at module root as the WebUI entry point).

apply_tanzanite_defaults() {
    # No volume-key prompts: fixed safe defaults for the whole
    # HyperOS 1.0 / 2.x / 3.0 tanzanite community.
    # live blur ON, high-end ON, screenshot-blur OFF, extra QS tiles ON.
    CHOICE_BLUR=true
    CHOICE_HE=true
    set_highend
    CHOICE_LEICA=false

    # Island only if already active (HyperOS 3+), otherwise force OFF.
    case "$(getprop persist.sys.feature.island)" in
        ""|0|false)
            CHOICE_ISLAND=false
            ;;
        *)
            CHOICE_ISLAND=true
            ;;
    esac

    define_props
    set_ssblur false
    remove_dead_overlays
    add_qs_tiles
    log "Tanzanite defaults by @noticesa applied."
}

# EOF
