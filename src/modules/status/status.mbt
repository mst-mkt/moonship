///|
pub struct StatusModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  success_symbol : String
  not_executable_symbol : String
  not_found_symbol : String
  map_symbol : Bool
}

///|
pub fn StatusModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "status",
  ),
) -> StatusModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="❌"),
    success_symbol: config.get_prop("success_symbol", default=""),
    not_executable_symbol: config.get_prop(
      "not_executable_symbol",
      default="🚫",
    ),
    not_found_symbol: config.get_prop("not_found_symbol", default="🔍"),
    map_symbol: config.get_prop("map_symbol") == "true",
  }
}

///|
pub fn StatusModule::from_config(config : @config.Config) -> StatusModule {
  StatusModule::new(config=config.get_module("status"))
}

///|
pub impl @ms.PromptModule for StatusModule with name(_self) -> String {
  "status"
}

///|
pub impl @ms.PromptModule for StatusModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard ctx.status != 0 || not(self.success_symbol.is_empty()) else {
    return Skipped("success exit code")
  }

  let status_str = ctx.status.to_string()
  let symbol = if ctx.status == 0 {
    self.success_symbol
  } else if self.map_symbol {
    match ctx.status {
      126 => self.not_executable_symbol
      127 => self.not_found_symbol
      _ => self.symbol
    }
  } else {
    self.symbol
  }

  let vars : Map[String, String] = {
    "status": status_str,
    "int": status_str,
    "symbol": symbol,
    "style": self.style,
  }
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}
