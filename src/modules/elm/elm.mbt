///|
pub struct ElmModule {
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
pub fn ElmModule::default() -> ElmModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "cyan bold",
    symbol: "🌳 ",
    detect_files: ["elm.json", "elm-package.json", ".elm-version"],
    detect_folders: ["elm-stuff"],
    detect_extensions: [".elm"],
  }
}

///|
pub fn ElmModule::from_toml_table(table : @config.ModuleTable) -> ElmModule {
  let d = ElmModule::default()
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
pub fn ElmModule::from_config(config : @config.Config) -> ElmModule {
  match config.get_raw_module("elm") {
    Some(table) => ElmModule::from_toml_table(table)
    None => ElmModule::default()
  }
}

///|
pub impl @ms.PromptModule for ElmModule with name(_self) -> String {
  "elm"
}

///|
pub impl @ms.PromptModule for ElmModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for ElmModule with execute(
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
    return Skipped("no Elm project detected")
  }

  let version = @exec.exec_cmd("elm", ["--version"])
  guard not(version.is_empty()) else { return Skipped("elm not found") }

  let vars : Map[String, String] = {
    "version": @exec.add_v_prefix(version),
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
pub fn ElmModule::schema() -> @config.ModuleSchema {
  let d = ElmModule::default()
  {
    name: "elm",
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
    ],
  }
}
