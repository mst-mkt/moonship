///|
pub struct PixiModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  version_format : String
  pixi_binary : String
  show_default_environment : Bool
  detect_files : Array[String]
  detect_extensions : Array[String]
  detect_folders : Array[String]
}

///|
pub fn PixiModule::default() -> PixiModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )(\\($environment\\) )]($style)",
    style: "yellow bold",
    symbol: "🧚 ",
    version_format: "v${raw}",
    pixi_binary: "pixi",
    show_default_environment: true,
    detect_files: ["pixi.toml", "pixi.lock"],
    detect_extensions: [],
    detect_folders: [],
  }
}

///|
pub fn PixiModule::from_table(table : @config.ModuleTable) -> PixiModule {
  let d = PixiModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    version_format: table
    .get_string("version_format")
    .unwrap_or(d.version_format),
    pixi_binary: table.get_string("pixi_binary").unwrap_or(d.pixi_binary),
    show_default_environment: table
    .get_bool("show_default_environment")
    .unwrap_or(d.show_default_environment),
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
pub fn PixiModule::from_config(config : @config.Config) -> PixiModule {
  match config.get_raw_module("pixi") {
    Some(table) => PixiModule::from_table(table)
    None => PixiModule::default()
  }
}

///|
pub impl @ms.PromptModule for PixiModule with name(_self) -> String {
  "pixi"
}

///|
pub impl @ms.PromptModule for PixiModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for PixiModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let env_name = @sys.get_env_var("PIXI_ENVIRONMENT_NAME").unwrap_or("")
  let has_env = not(env_name.is_empty())

  guard has_env ||
    @exec.detect_project(
      ctx.cwd,
      self.detect_files,
      self.detect_extensions,
      folders=self.detect_folders,
    ) else {
    return Skipped("no Pixi project detected")
  }

  let version = @exec.exec_cmd(self.pixi_binary, ["--version"])
  let vars : Map[String, String] = {
    "symbol": self.symbol,
    "style": self.style,
  }

  if not(version.is_empty()) {
    let ver = match @exec.split_to_strings(version, " ") {
      [_, v, ..] => v
      _ => version
    }
    vars["version"] = @exec.format_version(ver, self.version_format)
  }

  if has_env && (self.show_default_environment || env_name != "default") {
    vars["environment"] = env_name
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
pub fn PixiModule::schema() -> @config.ModuleSchema {
  let d = PixiModule::default()
  {
    name: "pixi",
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
        name: "show_default_environment",
        field_type: @config.FBool,
        default_value: d.show_default_environment.to_string(),
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
        name: "pixi_binary",
        field_type: @config.FString,
        default_value: d.pixi_binary,
      },
      {
        name: "version_format",
        field_type: @config.FString,
        default_value: d.version_format,
      },
    ],
  }
}
