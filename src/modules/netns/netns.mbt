///|
pub struct NetnsModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn NetnsModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("netns"),
) -> NetnsModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🛜"),
  }
}

///|
pub fn NetnsModule::from_config(config : @config.Config) -> NetnsModule {
  NetnsModule::new(config=config.get_module("netns"))
}

///|
pub impl @ms.PromptModule for NetnsModule with name(_self) -> String {
  "netns"
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
