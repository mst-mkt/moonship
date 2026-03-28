///|
pub struct KotlinModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  version_format : String
  kotlin_binary : String
  detect_files : Array[String]
  detect_extensions : Array[String]
  detect_folders : Array[String]
}

///|
pub fn KotlinModule::default() -> KotlinModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold blue",
    symbol: "🅺 ",
    version_format: "v${raw}",
    kotlin_binary: "kotlin",
    detect_files: [],
    detect_extensions: [".kt", ".kts"],
    detect_folders: [],
  }
}

///|
pub fn KotlinModule::from_table(table : @config.ModuleTable) -> KotlinModule {
  let d = KotlinModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    version_format: table
    .get_string("version_format")
    .unwrap_or(d.version_format),
    kotlin_binary: table.get_string("kotlin_binary").unwrap_or(d.kotlin_binary),
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
pub fn KotlinModule::from_config(config : @config.Config) -> KotlinModule {
  match config.get_raw_module("kotlin") {
    Some(table) => KotlinModule::from_table(table)
    None => KotlinModule::default()
  }
}

///|
pub impl @ms.PromptModule for KotlinModule with name(_self) -> String {
  "kotlin"
}

///|
pub impl @ms.PromptModule for KotlinModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for KotlinModule with execute(
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
    return Skipped("no Kotlin project detected")
  }

  let output = @exec.exec_cmd(self.kotlin_binary, ["-version"])
  guard not(output.is_empty()) else { return Skipped("kotlin not found") }

  let display = parse_kotlin_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse kotlin version")
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
fn parse_kotlin_version(output : String) -> String {
  @exec.split_to_strings(output, " ")
  .iter()
  .find_first(fn(s) {
    not(s.is_empty()) &&
    s.iter().nth(0).map(fn(c) { c >= '0' && c <= '9' }).unwrap_or(false)
  })
  .map(fn(s) { extract_version_digits(s) })
  .unwrap_or("")
}

///|
pub fn KotlinModule::schema() -> @config.ModuleSchema {
  let d = KotlinModule::default()
  {
    name: "kotlin",
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
        name: "kotlin_binary",
        field_type: @config.FString,
        default_value: d.kotlin_binary,
      },
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
      {
        name: "detect_folders",
        field_type: @config.FStringArray,
        default_value: d.detect_folders.join(", "),
      },
      {
        name: "version_format",
        field_type: @config.FString,
        default_value: d.version_format,
      },
    ],
  }
}
