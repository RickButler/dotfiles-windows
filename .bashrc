function vim_tmux() { tmux new -d "vim $*" \; attach; }
alias vim='vim_tmux'
