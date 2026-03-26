///|
pub struct OdinModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  show_commit : Bool
  version_format : String
  detect_files : Array[String]
  detect_extensions : Array[String]
  detect_folders : Array[String]
}

///|
pub fn OdinModule::default() -> OdinModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold bright-blue",
    symbol: "Ø ",
    show_commit: false,
    version_format: "v${raw}",
    detect_files: [],
    detect_extensions: [".odin"],
    detect_folders: [],
  }
}

///|
pub fn OdinModule::from_table(table : @config.ModuleTable) -> OdinModule {
  let d = OdinModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    show_commit: table.get_bool("show_commit").unwrap_or(d.show_commit),
    version_format: table
    .get_string("version_format")
    .unwrap_or(d.version_format),
    detect_files: table
    .get_string_array("detect_files")
    .unwrap_or(d.detect_files),
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(d.detect_extensions),
    detect_folders: table
    .get_string_array("detect_folders")
    .unwrap_or(d.detect_folders),
  }
}

///|
pub fn OdinModule::from_config(config : @config.Config) -> OdinModule {
  match config.get_raw_module("odin") {
    Some(table) => OdinModule::from_table(table)
    None => OdinModule::default()
  }
}

///|
pub impl @ms.PromptModule for OdinModule with name(_self) -> String {
  "odin"
}

///|
pub impl @ms.PromptModule for OdinModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for OdinModule with execute(
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
    return Skipped("no Odin project detected")
  }

  let output = @exec.exec_cmd("odin", ["version"])
  guard not(output.is_empty()) else { return Skipped("odin not found") }

  let display = parse_odin_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse odin version")
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
fn parse_odin_version(output : String) -> String {
  output.split(" ").fold(init="", fn(_prev, s) { s.to_string() })
}

///|
pub fn OdinModule::schema() -> @config.ModuleSchema {
  let d = OdinModule::default()
  {
    name: "odin",
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
