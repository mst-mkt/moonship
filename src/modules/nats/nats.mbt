///|
pub struct NatsModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn NatsModule::default() -> NatsModule {
  {
    disabled: true,
    async_render: false,
    format: "[$symbol($name )]($style)",
    style: "bold purple",
    symbol: "✉️ ",
  }
}

///|
pub fn NatsModule::from_toml_table(table : @config.ModuleTable) -> NatsModule {
  let d = NatsModule::default()
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
pub fn NatsModule::from_config(config : @config.Config) -> NatsModule {
  match config.get_raw_module("nats") {
    Some(table) => NatsModule::from_toml_table(table)
    None => NatsModule::default()
  }
}

///|
pub impl @ms.PromptModule for NatsModule with name(_self) -> String {
  "nats"
}

///|
pub impl @ms.PromptModule for NatsModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for NatsModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let output = @exec.exec_cmd("nats", ["context", "info", "--json"])
  guard not(output.is_empty()) else { return Skipped("nats not found") }

  let name = parse_nats_context_name(output)
  guard not(name.is_empty()) else {
    return Skipped("could not parse nats context")
  }

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
fn parse_nats_context_name(json : String) -> String {
  let key = "\"name\""
  match json.find(key) {
    None => ""
    Some(idx) => {
      let after = json[idx + key.length():].to_string()
      let colon = match after.find(":") {
        Some(p) => p
        None => return ""
      }

      let after_colon = after[colon + 1:].to_string()
      let quote_start = match after_colon.find("\"") {
        Some(p) => p
        None => return ""
      }

      let after_quote = after_colon[quote_start + 1:].to_string()
      let quote_end = match after_quote.find("\"") {
        Some(p) => p
        None => return ""
      }

      after_quote[:quote_end].to_string()
    }
  }
}
