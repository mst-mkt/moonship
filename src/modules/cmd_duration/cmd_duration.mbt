///|
pub struct CmdDurationModule {
  disabled : Bool
  format : String
  style : String
  min_time : Int
}

///|
pub fn CmdDurationModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "cmd_duration",
  ),
) -> CmdDurationModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    min_time: config.get_int_prop("min_time", default=2000),
  }
}

///|
pub fn CmdDurationModule::from_config(
  config : @config.Config,
) -> CmdDurationModule {
  CmdDurationModule::new(config=config.get_module("cmd_duration"))
}

///|
pub impl @ms.PromptModule for CmdDurationModule with name(_self) -> String {
  "cmd_duration"
}

///|
pub impl @ms.PromptModule for CmdDurationModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard ctx.cmd_duration >= self.min_time else {
    return Skipped("duration below min_time")
  }

  let duration = format_duration(ctx.cmd_duration)
  let style = @terminal.parse_style(self.style)
  let vars : Map[String, String] = { "duration": duration, "style": self.style }
  let segments = @ms.format_string(self.format, vars, style)

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn format_duration(ms : Int) -> String {
  if ms < 1000 {
    return "\{ms}ms"
  }

  let total_secs = ms / 1000
  let hours = total_secs / 3600
  let minutes = total_secs % 3600 / 60
  let seconds = total_secs % 60

  if hours > 0 {
    "\{hours}h\{minutes}m\{seconds}s"
  } else if minutes > 0 {
    "\{minutes}m\{seconds}s"
  } else {
    "\{seconds}s"
  }
}
