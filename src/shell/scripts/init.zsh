# moonship init script for zsh
# Usage: eval "$(moonship init zsh)"

export MOONSHIP_SHELL="zsh"
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

# Async prompt callback: read result from fd and redraw
__moonship_async_callback() {
  local fd=$1
  local result
  if read -r -u "$fd" result 2>/dev/null; then
    if [[ -n "$result" ]]; then
      PROMPT="$result"
      zle && zle reset-prompt
    fi
  fi
  zle -F "$fd"
  exec {fd}<&-
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
  local prompt_args=(
    --status="$exit_code"
    --cmd-duration="$cmd_duration"
    --jobs="${jobs_count:-0}"
    --terminal-width="${term_width:-80}"
  )

  # Synchronous prompt (uses cache if available)
  PROMPT=$("$MOONSHIP_BIN" prompt "${prompt_args[@]}")

  # Clean up previous async fd if still open
  if [[ -n "$MOONSHIP_ASYNC_FD" ]]; then
    zle -F "$MOONSHIP_ASYNC_FD" 2>/dev/null
    exec {MOONSHIP_ASYNC_FD}<&- 2>/dev/null
    unset MOONSHIP_ASYNC_FD
  fi

  # Async update: recompute in background, update cache, redraw
  exec {MOONSHIP_ASYNC_FD} < <("$MOONSHIP_BIN" prompt --async "${prompt_args[@]}")
  zle -F "$MOONSHIP_ASYNC_FD" __moonship_async_callback
}

# Install hooks
autoload -Uz add-zsh-hook
add-zsh-hook precmd __moonship_precmd
add-zsh-hook preexec __moonship_preexec

# Trigger initial prompt
__moonship_precmd
