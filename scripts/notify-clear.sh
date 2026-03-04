#!/usr/bin/env bash
# notify-clear.sh -- Clear all notifications
set -euo pipefail

get_session_name() {
  tmux display-message -p '#{session_name}'
}

SESSION=$(get_session_name)
NOTIFY_FILE="/tmp/tmux-notifications-${SESSION}"

if [[ -f "$NOTIFY_FILE" ]]; then
  rm "$NOTIFY_FILE"
fi

tmux display-message "Notifications cleared"
