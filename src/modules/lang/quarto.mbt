///|
pub struct QuartoModule {
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
pub fn QuartoModule::default() -> QuartoModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold #75AADB",
    symbol: "⨁ ",
    version_format: "v${raw}",
    detect_files: ["_quarto.yml"],
    detect_extensions: [".qmd"],
    detect_folders: [],
  }
}

///|
pub fn QuartoModule::from_table(table : @config.ModuleTable) -> QuartoModule {
  let d = QuartoModule::default()
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
pub fn QuartoModule::from_config(config : @config.Config) -> QuartoModule {
  match config.get_raw_module("quarto") {
    Some(table) => QuartoModule::from_table(table)
    None => QuartoModule::default()
  }
}

///|
pub impl @ms.PromptModule for QuartoModule with name(_self) -> String {
  "quarto"
}

///|
pub impl @ms.PromptModule for QuartoModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for QuartoModule with execute(
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
    return Skipped("no Quarto project detected")
  }

  let version = @exec.exec_cmd("quarto", ["--version"])
  guard not(version.is_empty()) else { return Skipped("quarto not found") }

  let vars : Map[String, String] = {
    "version": @exec.format_version(version, self.version_format),
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
pub fn QuartoModule::schema() -> @config.ModuleSchema {
  let d = QuartoModule::default()
  {
    name: "quarto",
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
