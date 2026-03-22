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
pub fn CustomModule::from_table(table : @config.ModuleTable) -> CustomModule {
  let d = CustomModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    command: table.get_string("command").unwrap_or(d.command),
  }
}

///|
pub fn CustomModule::from_config(config : @config.Config) -> CustomModule {
  match config.get_raw_module("custom") {
    Some(table) => CustomModule::from_table(table)
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

///|
pub fn CustomModule::schema() -> @config.ModuleSchema {
  let d = CustomModule::default()
  {
    name: "custom",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
      { name: "command", field_type: @config.FString, default_value: d.command },
    ],
  }
}
