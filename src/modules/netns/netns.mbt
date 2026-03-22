///|
pub struct NetnsModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn NetnsModule::default() -> NetnsModule {
  {
    disabled: false,
    async_render: false,
    format: "[$symbol \\[$name\\]]($style) ",
    style: "blue bold dimmed",
    symbol: "🛜",
  }
}

///|
pub fn NetnsModule::from_toml_table(table : @config.ModuleTable) -> NetnsModule {
  let d = NetnsModule::default()
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
pub fn NetnsModule::from_config(config : @config.Config) -> NetnsModule {
  match config.get_raw_module("netns") {
    Some(table) => NetnsModule::from_toml_table(table)
    None => NetnsModule::default()
  }
}

///|
pub impl @ms.PromptModule for NetnsModule with name(_self) -> String {
  "netns"
}

///|
pub impl @ms.PromptModule for NetnsModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for NetnsModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let name = @exec.exec_cmd("ip", ["netns", "identify"])
  guard not(name.is_empty()) else { return Skipped("not in network namespace") }

  let vars : Map[String, String] = {
    "name": name,
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
pub fn NetnsModule::schema() -> @config.ModuleSchema {
  let d = NetnsModule::default()
  {
    name: "netns",
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
