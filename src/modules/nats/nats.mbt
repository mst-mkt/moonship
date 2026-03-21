///|
pub struct NatsModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn NatsModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("nats"),
) -> NatsModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="✉️ "),
  }
}

///|
pub fn NatsModule::from_config(config : @config.Config) -> NatsModule {
  NatsModule::new(config=config.get_module("nats"))
}

///|
pub impl @ms.PromptModule for NatsModule with name(_self) -> String {
  "nats"
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
