#!/usr/bin/env bash
# jumplist-forward.sh -- Navigate forward in the jumplist
set -euo pipefail

get_session_name() {
  tmux display-message -p '#{session_name}'
}

jumplist_file() {
  echo "/tmp/tmux-jumplist"
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

  if (( pos <= 0 )); then
    tmux display-message "Jumplist: at newest entry"
    return 0
  fi

  if [[ ! -f "$jf" ]]; then
    tmux display-message "Jumplist: empty"
    return 0
  fi

  local -a entries=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && entries+=("$line")
  done < "$jf"

  local total=${#entries[@]}

  # Try to find next valid entry going forward (toward index 0)
  local new_pos=$((pos - 1))
  while (( new_pos >= 0 )); do
    local entry="${entries[$new_pos]}"
    local target_pane target_window
    target_pane=$(echo "$entry" | cut -d'|' -f1)
    target_window=$(echo "$entry" | cut -d'|' -f2)

    if pane_exists "$target_pane"; then
      local target_session
      target_session=$(echo "$entry" | cut -d'|' -f3)
      # Set suppression flag so hooks don't record this navigation
      tmux set-environment TMUX_JUMPLIST_SUPPRESS 1
      tmux switch-client -t "${target_session}" 2>/dev/null || true
      tmux select-window -t "$target_window" 2>/dev/null || true
      tmux select-pane -t "$target_pane" 2>/dev/null || true
      set_pos "$new_pos"
      return 0
    fi

    # Dead pane, skip it
    new_pos=$((new_pos - 1))
  done

  tmux display-message "Jumplist: at newest entry"
  set_pos 0
}

main
