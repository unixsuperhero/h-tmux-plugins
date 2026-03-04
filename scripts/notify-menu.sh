#!/usr/bin/env bash
# notify-menu.sh -- Show a display-menu of notifications
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

get_session_name() {
  tmux display-message -p '#{session_name}'
}

SESSION=$(get_session_name)
NOTIFY_FILE="/tmp/tmux-notifications-${SESSION}"

if [[ ! -f "$NOTIFY_FILE" ]] || [[ ! -s "$NOTIFY_FILE" ]]; then
  tmux display-message "No notifications"
  exit 0
fi

# Build display-menu arguments
MENU_ARGS=(-T "Notifications")
INDEX=0

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  if (( INDEX >= 10 )); then
    break
  fi

  PANE_ID=$(echo "$line" | cut -d'|' -f1)
  COMMAND_NAME=$(echo "$line" | cut -d'|' -f5)
  MESSAGE=$(echo "$line" | cut -d'|' -f6-)

  # Truncate message for display
  local_msg="$MESSAGE"
  if (( ${#local_msg} > 50 )); then
    local_msg="${local_msg:0:47}..."
  fi

  LABEL="${INDEX}: [${PANE_ID}] ${COMMAND_NAME}: ${local_msg}"
  MENU_ARGS+=("$LABEL" "$INDEX" "run-shell '${SCRIPT_DIR}/notify-jump.sh ${INDEX}'")

  INDEX=$((INDEX + 1))
done < "$NOTIFY_FILE"

if (( INDEX == 0 )); then
  tmux display-message "No notifications"
  exit 0
fi

# Add separator and clear option
MENU_ARGS+=("" "" "Clear all" "c" "run-shell '${SCRIPT_DIR}/notify-clear.sh'")

tmux display-menu "${MENU_ARGS[@]}"
