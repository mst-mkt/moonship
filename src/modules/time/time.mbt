///|
pub struct TimeModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  use_12hr : Bool
  time_format : String
  utc_time_offset : String
}

///|
pub fn TimeModule::default() -> TimeModule {
  {
    disabled: true,
    async_render: false,
    format: "at [$time]($style) ",
    style: "bold yellow",
    use_12hr: false,
    time_format: "",
    utc_time_offset: "local",
  }
}

///|
pub fn TimeModule::from_table(table : @config.ModuleTable) -> TimeModule {
  let d = TimeModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    use_12hr: table.get_bool("use_12hr").unwrap_or(d.use_12hr),
    time_format: table.get_string("time_format").unwrap_or(d.time_format),
    utc_time_offset: table
    .get_string("utc_time_offset")
    .unwrap_or(d.utc_time_offset),
  }
}

///|
pub fn TimeModule::from_config(config : @config.Config) -> TimeModule {
  match config.get_raw_module("time") {
    Some(table) => TimeModule::from_table(table)
    None => TimeModule::default()
  }
}

///|
pub impl @ms.PromptModule for TimeModule with name(_self) -> String {
  "time"
}

///|
pub impl @ms.PromptModule for TimeModule with is_async(self) -> Bool {
  self.async_render
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
    "UTC-\{offset[1:].to_string()}"
  } else if offset.has_prefix("-") {
    "UTC+\{offset[1:].to_string()}"
  } else {
    "UTC-\{offset}"
  }
}

///|
pub fn TimeModule::schema() -> @config.ModuleSchema {
  let d = TimeModule::default()
  {
    name: "time",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      {
        name: "use_12hr",
        field_type: @config.FBool,
        default_value: d.use_12hr.to_string(),
      },
      {
        name: "time_format",
        field_type: @config.FString,
        default_value: d.time_format,
      },
      {
        name: "utc_time_offset",
        field_type: @config.FString,
        default_value: d.utc_time_offset,
      },
    ],
  }
}
