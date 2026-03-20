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

# Async prompt callback: update prompt when async computation completes
__moonship_async_callback() {
  local fd=$1
  local result
  result=$(cat <&$fd 2>/dev/null)
  if [[ -n "$result" ]]; then
    PROMPT="$result"
    zle && zle reset-prompt
  fi
  zle -F "$fd"
  exec {fd}<&-
}

# precmd: called before each prompt
__moonship_precmd() {
  local exit_code=$?

  # Clean up previous async fd immediately to prevent stale callbacks
  if [[ -n "$MOONSHIP_ASYNC_FD" ]]; then
    zle -F "$MOONSHIP_ASYNC_FD" 2>/dev/null
    exec {MOONSHIP_ASYNC_FD}<&- 2>/dev/null
    unset MOONSHIP_ASYNC_FD
  fi

  local cmd_duration=0
  if [[ -n "$MOONSHIP_START_TIME" ]]; then
    __moonship_get_time
    local end_time=$MOONSHIP_CAPTURED_TIME
    cmd_duration=$((end_time - MOONSHIP_START_TIME))
    unset MOONSHIP_START_TIME
  fi

  local jobs_count=${(%):-%j}
  local term_width=$COLUMNS
  MOONSHIP_PROMPT_ARGS=(
    --status="$exit_code"
    --cmd-duration="$cmd_duration"
    --jobs="${jobs_count:-0}"
    --terminal-width="${term_width:-80}"
    --keymap="${KEYMAP:-}"
  )

  # Synchronous prompt (uses cache if available)
  local raw=$("$MOONSHIP_BIN" prompt "${MOONSHIP_PROMPT_ARGS[@]}")
  PROMPT="$raw"

  # Async update: recompute in background, update cache, redraw
  exec {MOONSHIP_ASYNC_FD} < <("$MOONSHIP_BIN" prompt --async "${MOONSHIP_PROMPT_ARGS[@]}")
  zle -F "$MOONSHIP_ASYNC_FD" __moonship_async_callback 2>/dev/null
}

# Keymap change: redraw prompt with new keymap
__moonship_zle_keymap_select() {
  local raw=$("$MOONSHIP_BIN" prompt "${MOONSHIP_PROMPT_ARGS[@]}" --keymap="$KEYMAP")
  PROMPT="$raw"
  zle reset-prompt
}

# Install hooks
autoload -Uz add-zsh-hook
add-zsh-hook precmd __moonship_precmd
add-zsh-hook preexec __moonship_preexec
zle -N zle-keymap-select __moonship_zle_keymap_select

# Trigger initial prompt
__moonship_precmd
