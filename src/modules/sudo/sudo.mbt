///|
pub struct SudoModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn SudoModule::default() -> SudoModule {
  {
    disabled: true,
    async_render: false,
    format: "[as $symbol]($style)",
    style: "bold blue",
    symbol: "🧙 ",
  }
}

///|
pub fn SudoModule::from_toml_table(table : @config.ModuleTable) -> SudoModule {
  let d = SudoModule::default()
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
pub fn SudoModule::from_config(config : @config.Config) -> SudoModule {
  match config.get_raw_module("sudo") {
    Some(table) => SudoModule::from_toml_table(table)
    None => SudoModule::default()
  }
}

///|
pub impl @ms.PromptModule for SudoModule with name(_self) -> String {
  "sudo"
}

///|
pub impl @ms.PromptModule for SudoModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for SudoModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard is_sudo_cached() else { return Skipped("sudo credentials not cached") }

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
async fn is_sudo_cached() -> Bool {
  let (status, _) = @process.collect_stdout("sudo", ["-n", "true"][:]) catch {
    _ => return false
  }

  status == 0
}

///|
pub fn SudoModule::schema() -> @config.ModuleSchema {
  let d = SudoModule::default()
  {
    name: "sudo",
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
