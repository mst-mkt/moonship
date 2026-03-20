# moonship init script for fish
# Usage: moonship init fish | source

set -gx MOONSHIP_SHELL fish
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
  set -l prompt_args \
    --status "$exit_code" \
    --cmd-duration "$cmd_duration" \
    --jobs "$jobs_count" \
    --terminal-width "$term_width"

  # Synchronous prompt (uses cache if available)
  $MOONSHIP_BIN prompt $prompt_args

  # Async update: only on real precmd, not on SIGUSR1 repaint
  if not set -q __moonship_is_repaint
    $MOONSHIP_BIN prompt --async $prompt_args >/dev/null 2>/dev/null &
    disown
  end
  set -e __moonship_is_repaint
end

function __moonship_preexec --on-event fish_preexec
  __moonship_get_time
  set -g MOONSHIP_START_TIME $MOONSHIP_CAPTURED_TIME
end

# Repaint prompt when async update completes
function __moonship_repaint --on-signal SIGUSR1
  set -g __moonship_is_repaint 1
  commandline -f repaint 2>/dev/null
end
