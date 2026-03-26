///|
pub struct CModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  version_format : String
  detect_files : Array[String]
  detect_extensions : Array[String]
  detect_folders : Array[String]
  commands : Array[(String, String)]
}

///|
pub fn CModule::default() -> CModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version(-$name) )]($style)",
    style: "149 bold",
    symbol: "C ",
    version_format: "v${raw}",
    detect_files: [],
    detect_extensions: [".c", ".h"],
    detect_folders: [],
    commands: [
      ("cc", "--version"),
      ("gcc", "--version"),
      ("clang", "--version"),
    ],
  }
}

///|
pub fn CModule::from_table(table : @config.ModuleTable) -> CModule {
  let d = CModule::default()
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
    commands: d.commands,
  }
}

///|
pub fn CModule::from_config(config : @config.Config) -> CModule {
  match config.get_raw_module("c") {
    Some(table) => CModule::from_table(table)
    None => CModule::default()
  }
}

///|
pub impl @ms.PromptModule for CModule with name(_self) -> String {
  "c"
}

///|
pub impl @ms.PromptModule for CModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for CModule with execute(self, ctx : @context.Context) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(
    ctx.cwd,
    self.detect_files,
    self.detect_extensions,
    folders=self.detect_folders,
  ) else {
    return Skipped("no C project detected")
  }

  let output = @exec.try_commands(self.commands)
  guard not(output.is_empty()) else { return Skipped("cc not found") }

  let version = @exec.find_semver(output)
  guard not(version.is_empty()) else {
    return Skipped("could not parse cc version")
  }

  let vars : Map[String, String] = {
    "version": @exec.format_version(version, self.version_format),
    "symbol": self.symbol,
    "style": self.style,
  }

  let name = @exec.detect_compiler_name(output, [
    ("clang", "clang"),
    ("gcc", "Free Software Foundation"),
  ])
  if not(name.is_empty()) {
    vars["name"] = name
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
pub fn CModule::schema() -> @config.ModuleSchema {
  let d = CModule::default()
  {
    name: "c",
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
