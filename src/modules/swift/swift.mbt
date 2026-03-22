///|
pub struct SwiftModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn SwiftModule::default() -> SwiftModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold 202",
    symbol: "🐦 ",
    detect_files: ["Package.swift"],
    detect_extensions: [".swift"],
  }
}

///|
pub fn SwiftModule::from_toml_table(table : @config.ModuleTable) -> SwiftModule {
  let d = SwiftModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
    detect_files: @config.get_toml_string_array(table, "detect_files").unwrap_or(
      d.detect_files,
    ),
    detect_extensions: @config.get_toml_string_array(table, "detect_extensions").unwrap_or(
      d.detect_extensions,
    ),
  }
}

///|
pub fn SwiftModule::from_config(config : @config.Config) -> SwiftModule {
  match config.get_raw_module("swift") {
    Some(table) => SwiftModule::from_toml_table(table)
    None => SwiftModule::default()
  }
}

///|
pub impl @ms.PromptModule for SwiftModule with name(_self) -> String {
  "swift"
}

///|
pub impl @ms.PromptModule for SwiftModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for SwiftModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Swift project detected")
  }

  let output = @exec.exec_cmd("swift", ["--version"])
  guard not(output.is_empty()) else { return Skipped("swift not found") }

  let display = parse_swift_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse swift version")
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
fn parse_swift_version(output : String) -> String {
  let parts = output.split(" ").collect()
  let mut version_next = false

  for i = 0; i < parts.length(); i = i + 1 {
    let s = parts[i].to_string()
    if version_next {
      return s
    }
    if s == "version" {
      version_next = true
    }
  }

  ""
}
