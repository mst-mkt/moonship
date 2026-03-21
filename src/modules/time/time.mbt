///|
pub struct TimeModule {
  disabled : Bool
  format : String
  style : String
  use_12hr : Bool
  time_format : String
  utc_time_offset : String
}

///|
pub fn TimeModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("time"),
) -> TimeModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    use_12hr: config.get_prop("use_12hr") == "true",
    time_format: config.get_prop("time_format", default=""),
    utc_time_offset: config.get_prop("utc_time_offset", default="local"),
  }
}

///|
pub fn TimeModule::from_config(config : @config.Config) -> TimeModule {
  TimeModule::new(config=config.get_module("time"))
}

///|
pub impl @ms.PromptModule for TimeModule with name(_self) -> String {
  "time"
}

///|
pub impl @ms.PromptModule for TimeModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let fmt = if not(self.time_format.is_empty()) {
    self.time_format
  } else if self.use_12hr {
    "%r"
  } else {
    "%T"
  }

  let time_str = if self.utc_time_offset == "local" {
    @exec.exec_cmd("date", ["+\{fmt}"])
  } else {
    let tz = make_posix_tz(self.utc_time_offset)
    @exec.exec_cmd("env", ["TZ=\{tz}", "date", "+\{fmt}"])
  }
  guard not(time_str.is_empty()) else { return Skipped("date not found") }

  let vars : Map[String, String] = { "time": time_str, "style": self.style }
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn make_posix_tz(offset : String) -> String {
  if offset.has_prefix("+") {
    "UTC-" + offset[1:].to_string()
  } else if offset.has_prefix("-") {
    "UTC+" + offset[1:].to_string()
  } else {
    "UTC-" + offset
  }
}
