#!/usr/bin/env bash
# jumplist-back.sh -- Navigate backward in the jumplist
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

get_session_name() {
  tmux display-message -p '#{session_name}'
}

jumplist_file() {
  echo "/tmp/tmux-jumplist-$(get_session_name)"
}

pos_file() {
  echo "$(jumplist_file).pos"
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

pane_exists() {
  tmux list-panes -a -F '#{pane_id}' 2>/dev/null | grep -qx "$1"
}

main() {
  local jf pos
  jf="$(jumplist_file)"
  pos=$(get_pos)

  if [[ ! -f "$jf" ]]; then
    tmux display-message "Jumplist: empty"
    return 0
  fi

  local -a entries=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && entries+=("$line")
  done < "$jf"

  local total=${#entries[@]}
  if (( total == 0 )); then
    tmux display-message "Jumplist: empty"
    return 0
  fi

  # If at position 0, first record current pane so we can come back with forward
  if (( pos == 0 )); then
    "$SCRIPT_DIR/jumplist.sh" record
    # Re-read entries after recording
    entries=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && entries+=("$line")
    done < "$jf"
    total=${#entries[@]}
    pos=0
  fi

  # Try to find next valid entry going backward
  local new_pos=$((pos + 1))
  while (( new_pos < total )); do
    local entry="${entries[$new_pos]}"
    local target_pane target_window
    target_pane=$(echo "$entry" | cut -d'|' -f1)
    target_window=$(echo "$entry" | cut -d'|' -f2)

    if pane_exists "$target_pane"; then
      # Set suppression flag so hooks don't record this navigation
      tmux set-environment TMUX_JUMPLIST_SUPPRESS 1
      tmux select-window -t "$target_window" 2>/dev/null || true
      tmux select-pane -t "$target_pane" 2>/dev/null || true
      set_pos "$new_pos"
      return 0
    fi

    # Dead pane, skip it
    new_pos=$((new_pos + 1))
  done

  tmux display-message "Jumplist: at oldest entry"
}

main
