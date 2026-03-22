///|
pub struct CobolModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn CobolModule::default() -> CobolModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold blue",
    symbol: "⚙️ ",
    detect_files: [],
    detect_extensions: [".cbl", ".cob", ".CBL", ".COB"],
  }
}

///|
pub fn CobolModule::from_table(table : @config.ModuleTable) -> CobolModule {
  let d = CobolModule::default()
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
pub fn CobolModule::from_config(config : @config.Config) -> CobolModule {
  match config.get_raw_module("cobol") {
    Some(table) => CobolModule::from_table(table)
    None => CobolModule::default()
  }
}

///|
pub impl @ms.PromptModule for CobolModule with name(_self) -> String {
  "cobol"
}

///|
pub impl @ms.PromptModule for CobolModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for CobolModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no COBOL project detected")
  }

  let output = @exec.exec_cmd("cobc", ["-version"])
  guard not(output.is_empty()) else { return Skipped("cobc not found") }

  let display = parse_cobol_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse cobol version")
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
fn parse_cobol_version(output : String) -> String {
  let parts = output.split(" ").collect()

  for i = 0; i < parts.length(); i = i + 1 {
    let s = parts[i].to_string()
    if not(s.is_empty()) &&
      s[0].unsafe_to_char() >= '0' &&
      s[0].unsafe_to_char() <= '9' {
      return extract_version_digits(s)
    }
  }

  ""
}

///|
fn extract_version_digits(s : String) -> String {
  let buf = StringBuilder::new()

  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i].unsafe_to_char()
    if (c >= '0' && c <= '9') || c == '.' {
      buf.write_char(c)
    } else {
      break
    }
  }

  buf.to_string()
}

///|
pub fn CobolModule::schema() -> @config.ModuleSchema {
  let d = CobolModule::default()
  {
    name: "cobol",
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
