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
pub fn GuixShellModule::from_table(
  table : @config.ModuleTable,
) -> GuixShellModule {
  let d = GuixShellModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
  }
}

///|
pub fn GuixShellModule::from_config(config : @config.Config) -> GuixShellModule {
  match config.get_raw_module("guix_shell") {
    Some(table) => GuixShellModule::from_table(table)
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

///|
pub fn GuixShellModule::schema() -> @config.ModuleSchema {
  let d = GuixShellModule::default()
  {
    name: "guix_shell",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
    ],
  }
}
