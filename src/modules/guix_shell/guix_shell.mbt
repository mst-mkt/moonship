///|
pub struct GuixShellModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn GuixShellModule::default() -> GuixShellModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol]($style) ",
    style: "yellow bold",
    symbol: "🐃 ",
  }
}

///|
pub fn GuixShellModule::from_toml_table(
  table : @config.ModuleTable,
) -> GuixShellModule {
  let d = GuixShellModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
  }
}

///|
pub fn GuixShellModule::from_config(config : @config.Config) -> GuixShellModule {
  match config.get_raw_module("guix_shell") {
    Some(table) => GuixShellModule::from_toml_table(table)
    None => GuixShellModule::default()
  }
}

///|
pub impl @ms.PromptModule for GuixShellModule with name(_self) -> String {
  "guix_shell"
}

///|
pub impl @ms.PromptModule for GuixShellModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for GuixShellModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let env = @sys.get_env_var("GUIX_ENVIRONMENT").unwrap_or("")
  guard not(env.is_empty()) else { return Skipped("not in guix shell") }

  let vars : Map[String, String] = {
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
