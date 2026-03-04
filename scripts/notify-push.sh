#!/usr/bin/env bash
# notify-push.sh -- Push a notification onto the stack
# Usage: notify-push.sh -p PANE_ID -w WINDOW_ID -s SESSION -c COMMAND "message"
set -euo pipefail

PANE_ID=""
WINDOW_ID=""
SESSION=""
COMMAND_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p) PANE_ID="$2"; shift 2 ;;
    -w) WINDOW_ID="$2"; shift 2 ;;
    -s) SESSION="$2"; shift 2 ;;
    -c) COMMAND_NAME="$2"; shift 2 ;;
    -*)
      echo "Unknown option: $1" >&2
      echo "Usage: notify-push.sh -p PANE_ID -w WINDOW_ID -s SESSION -c COMMAND \"message\"" >&2
      exit 1
      ;;
    *)  break ;;
  esac
done

MESSAGE="${1:-}"

if [[ -z "$PANE_ID" || -z "$WINDOW_ID" || -z "$SESSION" || -z "$MESSAGE" ]]; then
  echo "Usage: notify-push.sh -p PANE_ID -w WINDOW_ID -s SESSION -c COMMAND \"message\"" >&2
  exit 1
fi

NOTIFY_FILE="/tmp/tmux-notifications-${SESSION}"
TIMESTAMP=$(date +%s)

# Prepend new notification (newest first)
NEW_ENTRY="${PANE_ID}|${WINDOW_ID}|${SESSION}|${TIMESTAMP}|${COMMAND_NAME}|${MESSAGE}"

if [[ -f "$NOTIFY_FILE" ]]; then
  {
    echo "$NEW_ENTRY"
    cat "$NOTIFY_FILE"
  } > "${NOTIFY_FILE}.tmp"
  mv "${NOTIFY_FILE}.tmp" "$NOTIFY_FILE"
else
  echo "$NEW_ENTRY" > "$NOTIFY_FILE"
fi

# Optionally display a brief message in tmux
tmux display-message "Notification: ${MESSAGE}" 2>/dev/null || true
