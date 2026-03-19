# moonship init script for fish
# Usage: moonship init fish | source

set -g MOONSHIP_BIN '::BIN::'

function __moonship_get_time
  set -g MOONSHIP_CAPTURED_TIME ($MOONSHIP_BIN time)
end

function fish_prompt
  set -l exit_code $status
  set -l cmd_duration 0

  if set -q MOONSHIP_START_TIME
    __moonship_get_time
    set cmd_duration (math "$MOONSHIP_CAPTURED_TIME - $MOONSHIP_START_TIME")
    set -e MOONSHIP_START_TIME
  end

  set -l jobs_count (count (jobs -p))
  set -l term_width $COLUMNS

  $MOONSHIP_BIN prompt \
    --status="$exit_code" \
    --cmd-duration="$cmd_duration" \
    --jobs="$jobs_count" \
    --terminal-width="$term_width"
end

function __moonship_preexec --on-event fish_preexec
  __moonship_get_time
  set -g MOONSHIP_START_TIME $MOONSHIP_CAPTURED_TIME
end
