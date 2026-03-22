///|
pub struct PixiModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  show_default_environment : Bool
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn PixiModule::default() -> PixiModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )(\\($environment\\) )]($style)",
    style: "yellow bold",
    symbol: "🧚 ",
    show_default_environment: true,
    detect_files: ["pixi.toml", "pixi.lock"],
    detect_extensions: [],
  }
}

///|
pub fn PixiModule::from_toml_table(table : @config.ModuleTable) -> PixiModule {
  let d = PixiModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
    show_default_environment: @config.get_toml_bool(
      table, "show_default_environment",
    ).unwrap_or(d.show_default_environment),
    detect_files: @config.get_toml_string_array(table, "detect_files").unwrap_or(
      d.detect_files,
    ),
    detect_extensions: @config.get_toml_string_array(table, "detect_extensions").unwrap_or(
      d.detect_extensions,
    ),
  }
}

///|
pub fn PixiModule::from_config(config : @config.Config) -> PixiModule {
  match config.get_raw_module("pixi") {
    Some(table) => PixiModule::from_toml_table(table)
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
    @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Pixi project detected")
  }

  let version = @exec.exec_cmd("pixi", ["--version"])
  let vars : Map[String, String] = {
    "symbol": self.symbol,
    "style": self.style,
  }

  if not(version.is_empty()) {
    let parts = version.split(" ").collect()
    let ver = if parts.length() >= 2 { parts[1].to_string() } else { version }
    vars["version"] = @exec.add_v_prefix(ver)
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
