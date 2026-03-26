///|
pub struct CmdDurationModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  min_time : Int
  show_milliseconds : Bool
  show_notifications : Bool
  min_time_to_notify : Int
}

///|
pub fn CmdDurationModule::default() -> CmdDurationModule {
  {
    disabled: false,
    async_render: false,
    format: "took [$duration]($style) ",
    style: "yellow bold",
    min_time: 2000,
    show_milliseconds: false,
    show_notifications: false,
    min_time_to_notify: 45000,
  }
}

///|
pub fn CmdDurationModule::from_table(
  table : @config.ModuleTable,
) -> CmdDurationModule {
  let d = CmdDurationModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    min_time: table.get_int("min_time").unwrap_or(d.min_time),
    show_milliseconds: table
    .get_bool("show_milliseconds")
    .unwrap_or(d.show_milliseconds),
    show_notifications: table
    .get_bool("show_notifications")
    .unwrap_or(d.show_notifications),
    min_time_to_notify: table
    .get_int("min_time_to_notify")
    .unwrap_or(d.min_time_to_notify),
  }
}

///|
pub fn CmdDurationModule::from_config(
  config : @config.Config,
) -> CmdDurationModule {
  match config.get_raw_module("cmd_duration") {
    Some(table) => CmdDurationModule::from_table(table)
    None => CmdDurationModule::default()
  }
}

///|
pub impl @ms.PromptModule for CmdDurationModule with name(_self) -> String {
  "cmd_duration"
}

///|
pub impl @ms.PromptModule for CmdDurationModule with is_async(self) -> Bool {
  self.async_render
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

  // Send desktop notification if enabled
  if self.show_notifications && ctx.cmd_duration >= self.min_time_to_notify {
    ignore(
      @exec.exec_cmd(
        "notify-send",
        ["Command finished", "Took \{format_duration(ctx.cmd_duration, false)}"],
      ),
    )
  }

  let duration = format_duration(ctx.cmd_duration, self.show_milliseconds)
  let vars : Map[String, String] = { "duration": duration, "style": self.style }
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn format_duration(ms : Int, show_milliseconds : Bool) -> String {
  if ms < 1000 {
    return "\{ms}ms"
  }

  let total_secs = ms / 1000
  let remainder_ms = ms % 1000
  let hours = total_secs / 3600
  let minutes = total_secs % 3600 / 60
  let seconds = total_secs % 60

  let base = if hours > 0 {
    "\{hours}h\{minutes}m\{seconds}s"
  } else if minutes > 0 {
    "\{minutes}m\{seconds}s"
  } else {
    "\{seconds}s"
  }

  if show_milliseconds && remainder_ms > 0 {
    "\{base}\{remainder_ms}ms"
  } else {
    base
  }
}

///|
pub fn CmdDurationModule::schema() -> @config.ModuleSchema {
  let d = CmdDurationModule::default()
  {
    name: "cmd_duration",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      {
        name: "min_time",
        field_type: @config.FInt,
        default_value: d.min_time.to_string(),
      },
      {
        name: "show_milliseconds",
        field_type: @config.FBool,
        default_value: d.show_milliseconds.to_string(),
      },
    ],
  }
}
