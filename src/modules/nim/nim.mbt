///|
pub struct NimModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn NimModule::default() -> NimModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "yellow bold",
    symbol: "👑 ",
    detect_files: ["nim.cfg"],
    detect_extensions: [".nim", ".nims", ".nimble"],
  }
}

///|
pub fn NimModule::from_table(table : @config.ModuleTable) -> NimModule {
  let d = NimModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    detect_files: table
    .get_string_array("detect_files")
    .unwrap_or(d.detect_files),
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(d.detect_extensions),
  }
}

///|
pub fn NimModule::from_config(config : @config.Config) -> NimModule {
  match config.get_raw_module("nim") {
    Some(table) => NimModule::from_table(table)
    None => NimModule::default()
  }
}

///|
pub impl @ms.PromptModule for NimModule with name(_self) -> String {
  "nim"
}

///|
pub impl @ms.PromptModule for NimModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for NimModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Nim project detected")
  }

  let output = @exec.exec_cmd("nim", ["--version"])
  guard not(output.is_empty()) else { return Skipped("nim not found") }

  let display = parse_nim_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse nim version")
  }

  let vars : Map[String, String] = {
    "version": @exec.add_v_prefix(display),
    "symbol": self.symbol,
    "style": self.style,
  }
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn parse_nim_version(output : String) -> String {
  let parts = output.split(" ").collect()

  for i = 0; i < parts.length(); i = i + 1 {
    let s = parts[i].to_string()
    if not(s.is_empty()) && is_digit_or_dot(s) {
      return s
    }
  }

  ""
}

///|
fn is_digit_or_dot(s : String) -> Bool {
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i].unsafe_to_char()
    if not((c >= '0' && c <= '9') || c == '.') {
      return false
    }
  }

  true
}

///|
pub fn NimModule::schema() -> @config.ModuleSchema {
  let d = NimModule::default()
  {
    name: "nim",
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
        name: "detect_files",
        field_type: @config.FStringArray,
        default_value: d.detect_files.join(", "),
      },
      {
        name: "detect_extensions",
        field_type: @config.FStringArray,
        default_value: d.detect_extensions.join(", "),
      },
    ],
  }
}
