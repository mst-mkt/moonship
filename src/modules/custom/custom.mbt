///|
pub struct CustomModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  command : String
}

///|
pub fn CustomModule::default() -> CustomModule {
  {
    disabled: false,
    async_render: false,
    format: "[$symbol($output )]($style)",
    style: "green bold",
    symbol: "",
    command: "",
  }
}

///|
pub fn CustomModule::from_toml_table(
  table : @config.ModuleTable,
) -> CustomModule {
  let d = CustomModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
    command: @config.get_toml_string(table, "command").unwrap_or(d.command),
  }
}

///|
pub fn CustomModule::from_config(config : @config.Config) -> CustomModule {
  match config.get_raw_module("custom") {
    Some(table) => CustomModule::from_toml_table(table)
    None => CustomModule::default()
  }
}

///|
pub impl @ms.PromptModule for CustomModule with name(_self) -> String {
  "custom"
}

///|
pub impl @ms.PromptModule for CustomModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for CustomModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard not(self.command.is_empty()) else {
    return Skipped("no command configured")
  }

  let output = @exec.exec_cmd("sh", ["-c", self.command])
  guard not(output.is_empty()) else {
    return Skipped("command produced no output")
  }

  let vars : Map[String, String] = {
    "output": output,
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
