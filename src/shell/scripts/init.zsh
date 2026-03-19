# moonship init script for zsh
# Usage: eval "$(moonship init zsh)"

MOONSHIP_BIN='::BIN::'

# Capture start time for command duration
__moonship_get_time() {
  MOONSHIP_CAPTURED_TIME=$("$MOONSHIP_BIN" time)
}

# preexec: called just before a command is executed
__moonship_preexec() {
  __moonship_get_time
  MOONSHIP_START_TIME=$MOONSHIP_CAPTURED_TIME
}

# precmd: called before each prompt
__moonship_precmd() {
  local exit_code=$?
  local cmd_duration=0

  if [[ -n "$MOONSHIP_START_TIME" ]]; then
    __moonship_get_time
    local end_time=$MOONSHIP_CAPTURED_TIME
    cmd_duration=$((end_time - MOONSHIP_START_TIME))
    unset MOONSHIP_START_TIME
  fi

  local jobs_count=${(%):-%j}
  local term_width=$COLUMNS

  PROMPT=$("$MOONSHIP_BIN" prompt \
    --status="$exit_code" \
    --cmd-duration="$cmd_duration" \
    --jobs="${jobs_count:-0}" \
    --terminal-width="${term_width:-80}")
}

# Install hooks
autoload -Uz add-zsh-hook
add-zsh-hook precmd __moonship_precmd
add-zsh-hook preexec __moonship_preexec

# Trigger initial prompt
__moonship_precmd
