///|
pub struct DartModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_folders : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn DartModule::default() -> DartModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold blue",
    symbol: "🎯 ",
    detect_files: ["pubspec.yaml", "pubspec.yml", "pubspec.lock"],
    detect_folders: [".dart_tool"],
    detect_extensions: [".dart"],
  }
}

///|
pub fn DartModule::from_toml_table(table : @config.ModuleTable) -> DartModule {
  let d = DartModule::default()
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
    detect_folders: @config.get_toml_string_array(table, "detect_folders").unwrap_or(
      d.detect_folders,
    ),
    detect_extensions: @config.get_toml_string_array(table, "detect_extensions").unwrap_or(
      d.detect_extensions,
    ),
  }
}

///|
pub fn DartModule::from_config(config : @config.Config) -> DartModule {
  match config.get_raw_module("dart") {
    Some(table) => DartModule::from_toml_table(table)
    None => DartModule::default()
  }
}

///|
pub impl @ms.PromptModule for DartModule with name(_self) -> String {
  "dart"
}

///|
pub impl @ms.PromptModule for DartModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for DartModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(
    ctx.cwd,
    self.detect_files,
    self.detect_extensions,
    folders=self.detect_folders,
  ) else {
    return Skipped("no Dart project detected")
  }

  let output = @exec.exec_cmd("dart", ["--version"])
  guard not(output.is_empty()) else { return Skipped("dart not found") }

  let display = parse_dart_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse dart version")
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
fn parse_dart_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() >= 4 {
    parts[3].to_string()
  } else {
    ""
  }
}
