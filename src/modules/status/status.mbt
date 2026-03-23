///|
pub struct StatusModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  success_symbol : String
  not_executable_symbol : String
  not_found_symbol : String
  map_symbol : Bool
  pipestatus : Bool
  pipestatus_separator : String
  pipestatus_format : String
  pipestatus_segment_format : String
}

///|
pub fn StatusModule::default() -> StatusModule {
  {
    disabled: true,
    async_render: false,
    format: "[$symbol$status]($style) ",
    style: "bold red",
    symbol: "❌",
    success_symbol: "",
    not_executable_symbol: "🚫",
    not_found_symbol: "🔍",
    map_symbol: false,
    pipestatus: false,
    pipestatus_separator: "|",
    pipestatus_format: "\\[$pipestatus\\] => [$symbol$common_meaning$signal_name$maybe_int]($style) ",
    pipestatus_segment_format: "",
  }
}

///|
pub fn StatusModule::from_table(table : @config.ModuleTable) -> StatusModule {
  let d = StatusModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    success_symbol: table
    .get_string("success_symbol")
    .unwrap_or(d.success_symbol),
    not_executable_symbol: table
    .get_string("not_executable_symbol")
    .unwrap_or(d.not_executable_symbol),
    not_found_symbol: table
    .get_string("not_found_symbol")
    .unwrap_or(d.not_found_symbol),
    map_symbol: table.get_bool("map_symbol").unwrap_or(d.map_symbol),
    pipestatus: table.get_bool("pipestatus").unwrap_or(d.pipestatus),
    pipestatus_separator: table
    .get_string("pipestatus_separator")
    .unwrap_or(d.pipestatus_separator),
    pipestatus_format: table
    .get_string("pipestatus_format")
    .unwrap_or(d.pipestatus_format),
    pipestatus_segment_format: table
    .get_string("pipestatus_segment_format")
    .unwrap_or(d.pipestatus_segment_format),
  }
}

///|
pub fn StatusModule::from_config(config : @config.Config) -> StatusModule {
  match config.get_raw_module("status") {
    Some(table) => StatusModule::from_table(table)
    None => StatusModule::default()
  }
}

///|
pub impl @ms.PromptModule for StatusModule with name(_self) -> String {
  "status"
}

///|
pub impl @ms.PromptModule for StatusModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for StatusModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let has_pipestatus = self.pipestatus && ctx.pipestatus.length() > 1
  let any_pipe_failed = has_pipestatus &&
    ctx.pipestatus.iter().any(fn(s) { s != "0" })

  guard ctx.status != 0 || not(self.success_symbol.is_empty()) || any_pipe_failed else {
    return Skipped("success exit code")
  }
  let status_vars = self.build_status_vars(ctx.status)

  let format = if has_pipestatus {
    self.pipestatus_format
  } else {
    self.format
  }

  let vars = if has_pipestatus {
    let pipestatus_str = self.render_pipestatus(ctx.pipestatus)
    let merged : Map[String, String] = {}
    status_vars.each(fn(k, v) { merged[k] = v })
    merged["pipestatus"] = pipestatus_str
    merged
  } else {
    status_vars
  }

  let segments = @ms.format_string(
    format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn StatusModule::build_status_vars(
  self : StatusModule,
  status : Int,
) -> Map[String, String] {
  let status_str = status.to_string()

  let symbol = if status == 0 {
    self.success_symbol
  } else if self.map_symbol {
    match status {
      126 => self.not_executable_symbol
      127 => self.not_found_symbol
      _ => self.symbol
    }
  } else {
    self.symbol
  }

  let common_meaning = match status {
    1 => "ERROR"
    2 => "USAGE"
    126 => "NOPERM"
    127 => "NOTFOUND"
    _ => ""
  }

  let signal_name = if status > 128 {
    match status - 128 {
      1 => "HUP"
      2 => "INT"
      3 => "QUIT"
      6 => "ABRT"
      9 => "KILL"
      11 => "SEGV"
      13 => "PIPE"
      14 => "ALRM"
      15 => "TERM"
      _ => ""
    }
  } else {
    ""
  }

  let maybe_int = if common_meaning.is_empty() && signal_name.is_empty() {
    status_str
  } else {
    ""
  }

  {
    "status": status_str,
    "int": status_str,
    "hex_status": "0x" + hex_string(status),
    "symbol": symbol,
    "common_meaning": common_meaning,
    "signal_name": signal_name,
    "signal_number": if status > 128 {
      (status - 128).to_string()
    } else {
      ""
    },
    "maybe_int": maybe_int,
    "style": self.style,
  }
}

///|
fn StatusModule::render_pipestatus(
  self : StatusModule,
  statuses : Array[String],
) -> String {
  let seg_format = if self.pipestatus_segment_format.is_empty() {
    self.format
  } else {
    self.pipestatus_segment_format
  }

  statuses
  .map(fn(s) {
    let code = @strconv.parse_int(s) catch { _ => 0 }
    let vars = self.build_status_vars(code)
    let rendered = @ms.format_string(seg_format, vars, @terminal.Style::default())
    @ms.ModuleOutput::new(rendered).render()
  })
  .join(self.pipestatus_separator)
}

///|
fn hex_string(n : Int) -> String {
  let hex_chars = "0123456789ABCDEF"
  guard n != 0 else { return "0" }

  let abs_n = if n < 0 { -n } else { n }
  let buf = StringBuilder::new()
  let digits : Array[Char] = []

  loop abs_n {
    0 => ()
    v => {
      digits.push(hex_chars[v % 16].unsafe_to_char())
      continue v / 16
    }
  }

  if n < 0 {
    buf.write_char('-')
  }

  for i = digits.length() - 1; i >= 0; i = i - 1 {
    buf.write_char(digits[i])
  }

  buf.to_string()
}

///|
pub fn StatusModule::schema() -> @config.ModuleSchema {
  let d = StatusModule::default()
  {
    name: "status",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
      {
        name: "success_symbol",
        field_type: @config.FString,
        default_value: d.success_symbol,
      },
      {
        name: "not_executable_symbol",
        field_type: @config.FString,
        default_value: d.not_executable_symbol,
      },
      {
        name: "not_found_symbol",
        field_type: @config.FString,
        default_value: d.not_found_symbol,
      },
      {
        name: "map_symbol",
        field_type: @config.FBool,
        default_value: d.map_symbol.to_string(),
      },
      {
        name: "pipestatus",
        field_type: @config.FBool,
        default_value: d.pipestatus.to_string(),
      },
      {
        name: "pipestatus_separator",
        field_type: @config.FString,
        default_value: d.pipestatus_separator,
      },
      {
        name: "pipestatus_format",
        field_type: @config.FString,
        default_value: d.pipestatus_format,
      },
      {
        name: "pipestatus_segment_format",
        field_type: @config.FString,
        default_value: d.pipestatus_segment_format,
      },
    ],
  }
}
