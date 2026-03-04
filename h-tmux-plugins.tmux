#!/bin/bash
# h-tmux-plugins.tmux -- Main entry point (sourced by TPM)
# Provides: Jumplist navigation + Notification tracker

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${CURRENT_DIR}/scripts"

# Helper to read tmux option with default
get_option() {
  local option="$1"
  local default="$2"
  local value
  value=$(tmux show-option -gqv "$option" 2>/dev/null || true)
  echo "${value:-$default}"
}

# --- Configuration ---
JUMPLIST_SIZE=$(get_option "@jumplist-size" "50")
JUMPLIST_BACK_KEY=$(get_option "@jumplist-back-key" "C-k")
JUMPLIST_FORWARD_KEY=$(get_option "@jumplist-forward-key" "C-j")
NOTIFY_MENU_KEY=$(get_option "@notify-menu-key" "C-n")
NOTIFY_CLEAR_KEY=$(get_option "@notify-clear-key" "M-n")

# --- Jumplist hooks ---
# Register hooks to record navigation events (run in background with &)
tmux set-hook -g after-select-pane "run-shell -b '${SCRIPTS_DIR}/jumplist.sh record'"
tmux set-hook -g after-select-window "run-shell -b '${SCRIPTS_DIR}/jumplist.sh record'"

# --- Jumplist keybindings ---
tmux bind-key -r "$JUMPLIST_BACK_KEY" run-shell "${SCRIPTS_DIR}/jumplist-back.sh"
tmux bind-key -r "$JUMPLIST_FORWARD_KEY" run-shell "${SCRIPTS_DIR}/jumplist-forward.sh"

# --- Notification keybindings ---
tmux bind-key "$NOTIFY_MENU_KEY" run-shell "${SCRIPTS_DIR}/notify-menu.sh"
tmux bind-key "$NOTIFY_CLEAR_KEY" run-shell "${SCRIPTS_DIR}/notify-clear.sh"
