///|
pub struct TypstModule {
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
pub fn TypstModule::default() -> TypstModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold #0093A7",
    symbol: "t ",
    version_format: "v${raw}",
    detect_files: ["template.typ"],
    detect_extensions: [".typ"],
    detect_folders: [],
  }
}

///|
pub fn TypstModule::from_table(table : @config.ModuleTable) -> TypstModule {
  let d = TypstModule::default()
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
pub fn TypstModule::from_config(config : @config.Config) -> TypstModule {
  match config.get_raw_module("typst") {
    Some(table) => TypstModule::from_table(table)
    None => TypstModule::default()
  }
}

///|
pub impl @ms.PromptModule for TypstModule with name(_self) -> String {
  "typst"
}

///|
pub impl @ms.PromptModule for TypstModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for TypstModule with execute(
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
    return Skipped("no Typst project detected")
  }

  let output = @exec.exec_cmd("typst", ["--version"])
  guard not(output.is_empty()) else { return Skipped("typst not found") }

  let parts = output.split(" ").map(fn(s) { s.to_string() }).collect()
  guard parts.length() >= 2 else {
    return Skipped("could not parse typst version")
  }

  let version = parts[1]
  guard not(version.is_empty()) else {
    return Skipped("could not parse typst version")
  }

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
pub fn TypstModule::schema() -> @config.ModuleSchema {
  let d = TypstModule::default()
  {
    name: "typst",
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
