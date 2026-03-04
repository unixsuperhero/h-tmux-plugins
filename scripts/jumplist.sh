#!/usr/bin/env bash
# jumplist.sh -- Record navigation events for the tmux jumplist
# Usage: jumplist.sh record

set -euo pipefail

COMMAND="${1:-}"

get_session_name() {
  tmux display-message -p '#{session_name}'
}

jumplist_file() {
  echo "/tmp/tmux-jumplist-$(get_session_name)"
}

pos_file() {
  echo "$(jumplist_file).pos"
}

get_max_size() {
  local size
  size=$(tmux show-option -gqv @jumplist-size 2>/dev/null || true)
  echo "${size:-50}"
}

get_pos() {
  local pf
  pf="$(pos_file)"
  if [[ -f "$pf" ]]; then
    cat "$pf"
  else
    echo 0
  fi
}

set_pos() {
  echo "$1" > "$(pos_file)"
}

record() {
  # Check suppression flag via tmux environment
  local suppress
  suppress=$(tmux show-environment TMUX_JUMPLIST_SUPPRESS 2>/dev/null || true)
  if [[ "$suppress" == "TMUX_JUMPLIST_SUPPRESS=1" ]]; then
    tmux set-environment -u TMUX_JUMPLIST_SUPPRESS 2>/dev/null || true
    return 0
  fi

  local pane_id window_id session_name pane_cmd timestamp
  pane_id=$(tmux display-message -p '#{pane_id}')
  window_id=$(tmux display-message -p '#{window_id}')
  session_name=$(get_session_name)
  pane_cmd=$(tmux display-message -p '#{pane_current_command}')
  timestamp=$(date +%s)

  local jf pos
  jf="$(jumplist_file)"
  pos=$(get_pos)

  # Read current jumplist into array
  local -a entries=()
  if [[ -f "$jf" ]]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && entries+=("$line")
    done < "$jf"
  fi

  # If position is not at the head, truncate forward history
  if (( pos > 0 && ${#entries[@]} > 0 )); then
    entries=("${entries[@]:$pos}")
    set_pos 0
  elif (( pos > 0 )); then
    set_pos 0
  fi

  # Deduplicate: skip if the most recent entry is the same pane
  if (( ${#entries[@]} > 0 )); then
    local last_pane
    last_pane=$(echo "${entries[0]}" | cut -d'|' -f1)
    if [[ "$last_pane" == "$pane_id" ]]; then
      return 0
    fi
  fi

  # Prepend new entry (newest first)
  local new_entry="${pane_id}|${window_id}|${session_name}|${timestamp}|${pane_cmd}"
  local max_size
  max_size=$(get_max_size)

  {
    echo "$new_entry"
    if (( ${#entries[@]} > 0 )); then
      for entry in "${entries[@]}"; do
        echo "$entry"
      done
    fi
  } | head -n "$max_size" > "${jf}.tmp"
  mv "${jf}.tmp" "$jf"
}

case "$COMMAND" in
  record)
    record
    ;;
  *)
    echo "Usage: jumplist.sh record" >&2
    exit 1
    ;;
esac
