# moonship init script for bash
# Usage: eval "$(moonship init bash)"

export MOONSHIP_SHELL="bash"
MOONSHIP_BIN='::BIN::'

# Capture start time
__moonship_get_time() {
  MOONSHIP_CAPTURED_TIME=$("$MOONSHIP_BIN" time)
}

# preexec via DEBUG trap
MOONSHIP_PREEXEC_READY=true
__moonship_preexec() {
  __moonship_get_time
  MOONSHIP_START_TIME=$MOONSHIP_CAPTURED_TIME
}

__moonship_preexec_guard() {
  if [ "$MOONSHIP_PREEXEC_READY" = "true" ]; then
    MOONSHIP_PREEXEC_READY=false
    __moonship_preexec
  fi
}
trap '__moonship_preexec_guard' DEBUG

# precmd via PROMPT_COMMAND
__moonship_precmd() {
  local exit_code=$?
  MOONSHIP_PREEXEC_READY=true
  local cmd_duration=0

  if [[ -n "$MOONSHIP_START_TIME" ]]; then
    __moonship_get_time
    local end_time=$MOONSHIP_CAPTURED_TIME
    cmd_duration=$((end_time - MOONSHIP_START_TIME))
    unset MOONSHIP_START_TIME
  fi

  local jobs_count=$(jobs -p | wc -l)
  local term_width=${COLUMNS:-80}

  PS1=$("$MOONSHIP_BIN" prompt \
    --status "$exit_code" \
    --cmd-duration "$cmd_duration" \
    --jobs "$jobs_count" \
    --terminal-width "$term_width")
}

PROMPT_COMMAND="__moonship_precmd${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
