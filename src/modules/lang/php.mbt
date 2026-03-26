///|
pub struct PhpModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  version_format : String
  detect_files : Array[String]
  detect_extensions : Array[String]
  detect_folders : Array[String]
}

///|
pub fn PhpModule::default() -> PhpModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "147 bold",
    symbol: "🐘 ",
    version_format: "v${raw}",
    detect_files: ["composer.json", ".php-version"],
    detect_extensions: [".php"],
    detect_folders: [],
  }
}

///|
pub fn PhpModule::from_table(table : @config.ModuleTable) -> PhpModule {
  let d = PhpModule::default()
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
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(d.detect_extensions),
    detect_folders: table
    .get_string_array("detect_folders")
    .unwrap_or(d.detect_folders),
  }
}

///|
pub fn PhpModule::from_config(config : @config.Config) -> PhpModule {
  match config.get_raw_module("php") {
    Some(table) => PhpModule::from_table(table)
    None => PhpModule::default()
  }
}

///|
pub impl @ms.PromptModule for PhpModule with name(_self) -> String {
  "php"
}

///|
pub impl @ms.PromptModule for PhpModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for PhpModule with execute(
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
    return Skipped("no PHP project detected")
  }

  let output = @exec.exec_cmd("php", [
    "-nr", "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION.'.'.PHP_RELEASE_VERSION;",
  ])
  guard not(output.is_empty()) else { return Skipped("php not found") }

  let vars : Map[String, String] = {
    "version": @exec.format_version(output, self.version_format),
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
pub fn PhpModule::schema() -> @config.ModuleSchema {
  let d = PhpModule::default()
  {
    name: "php",
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
