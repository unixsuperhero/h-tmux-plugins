#!/usr/bin/env bash
# notify-jump.sh -- Jump to a notification's pane and dismiss it
# Usage: notify-jump.sh INDEX
set -euo pipefail

INDEX="${1:-}"

if [[ -z "$INDEX" ]]; then
  echo "Usage: notify-jump.sh INDEX" >&2
  exit 1
fi

get_session_name() {
  tmux display-message -p '#{session_name}'
}

SESSION=$(get_session_name)
NOTIFY_FILE="/tmp/tmux-notifications-${SESSION}"

if [[ ! -f "$NOTIFY_FILE" ]]; then
  tmux display-message "No notifications"
  exit 0
fi

# Read entries
ENTRY=$(sed -n "$((INDEX + 1))p" "$NOTIFY_FILE")

if [[ -z "$ENTRY" ]]; then
  tmux display-message "Notification not found"
  exit 0
fi

TARGET_PANE=$(echo "$ENTRY" | cut -d'|' -f1)
TARGET_WINDOW=$(echo "$ENTRY" | cut -d'|' -f2)

# Check if pane exists
if ! tmux list-panes -a -F '#{pane_id}' 2>/dev/null | grep -qx "$TARGET_PANE"; then
  tmux display-message "Pane $TARGET_PANE no longer exists"
  # Still remove the notification
  sed -i '' "$((INDEX + 1))d" "$NOTIFY_FILE" 2>/dev/null || sed -i "$((INDEX + 1))d" "$NOTIFY_FILE"
  exit 0
fi

# Jump to the pane
tmux select-window -t "$TARGET_WINDOW" 2>/dev/null || true
tmux select-pane -t "$TARGET_PANE" 2>/dev/null || true

# Remove the notification (macOS sed vs GNU sed)
sed -i '' "$((INDEX + 1))d" "$NOTIFY_FILE" 2>/dev/null || sed -i "$((INDEX + 1))d" "$NOTIFY_FILE"
