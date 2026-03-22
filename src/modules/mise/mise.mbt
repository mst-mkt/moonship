///|
pub struct MiseModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  healthy_symbol : String
  unhealthy_symbol : String
  detect_files : Array[String]
  detect_folders : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn MiseModule::default() -> MiseModule {
  {
    disabled: true,
    async_render: false,
    format: "on [$symbol$health]($style) ",
    style: "bold purple",
    symbol: "mise ",
    healthy_symbol: "healthy",
    unhealthy_symbol: "unhealthy",
    detect_files: [
      "mise.toml", "mise.local.toml", ".mise.toml", ".mise.local.toml",
    ],
    detect_folders: [".mise"],
    detect_extensions: [],
  }
}

///|
pub fn MiseModule::from_toml_table(table : @config.ModuleTable) -> MiseModule {
  let d = MiseModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
    healthy_symbol: @config.get_toml_string(table, "healthy_symbol").unwrap_or(
      d.healthy_symbol,
    ),
    unhealthy_symbol: @config.get_toml_string(table, "unhealthy_symbol").unwrap_or(
      d.unhealthy_symbol,
    ),
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
pub fn MiseModule::from_config(config : @config.Config) -> MiseModule {
  match config.get_raw_module("mise") {
    Some(table) => MiseModule::from_toml_table(table)
    None => MiseModule::default()
  }
}

///|
pub impl @ms.PromptModule for MiseModule with name(_self) -> String {
  "mise"
}

///|
pub impl @ms.PromptModule for MiseModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for MiseModule with execute(
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
    return Skipped("no mise project detected")
  }

  let doctor_output = @exec.exec_cmd("mise", ["doctor"])
  let health = if not(doctor_output.is_empty()) {
    self.healthy_symbol
  } else {
    self.unhealthy_symbol
  }

  let vars : Map[String, String] = {
    "symbol": self.symbol,
    "health": health,
    "style": self.style,
  }
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}
