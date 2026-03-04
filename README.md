# h-tmux-plugins

tmux plugins to work with ai/notifications

## Install

#### plain install:

tmux run-shell /path/to/h-tmux-plugins.tmux

#### with tpm:

set -g @plugin 'unixsuperhero/h-tmux-plugins'


## Testing

#### notification test:

~/proj/h-tmux-plugins/scripts/notify-push.sh -p %0 -w @0 -s main -c "test" "Hello"

