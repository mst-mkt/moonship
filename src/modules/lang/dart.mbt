///|
pub struct DartModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  version_format : String
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
    version_format: "v${raw}",
    detect_files: ["pubspec.yaml", "pubspec.yml", "pubspec.lock"],
    detect_folders: [".dart_tool"],
    detect_extensions: [".dart"],
  }
}

///|
pub fn DartModule::from_table(table : @config.ModuleTable) -> DartModule {
  let d = DartModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    version_format: table
    .get_string("version_format")
    .unwrap_or(d.version_format),
    detect_files: table
    .get_string_array("detect_files")
    .unwrap_or(d.detect_files),
    detect_folders: table
    .get_string_array("detect_folders")
    .unwrap_or(d.detect_folders),
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(d.detect_extensions),
  }
}

///|
pub fn DartModule::from_config(config : @config.Config) -> DartModule {
  match config.get_raw_module("dart") {
    Some(table) => DartModule::from_table(table)
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
    "version": @exec.format_version(display, self.version_format),
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
  match @exec.split_to_strings(output, " ") {
    [_, _, _, version, ..] => version
    _ => ""
  }
}

///|
pub fn DartModule::schema() -> @config.ModuleSchema {
  let d = DartModule::default()
  {
    name: "dart",
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
        name: "detect_folders",
        field_type: @config.FStringArray,
        default_value: d.detect_folders.join(", "),
      },
      {
        name: "detect_extensions",
        field_type: @config.FStringArray,
        default_value: d.detect_extensions.join(", "),
      },
      {
        name: "version_format",
        field_type: @config.FString,
        default_value: d.version_format,
      },
    ],
  }
}
