///|
pub struct CustomModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  command : String
}

///|
pub fn CustomModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "custom",
  ),
) -> CustomModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default=""),
    command: config.get_prop("command", default=""),
  }
}

///|
pub fn CustomModule::from_config(config : @config.Config) -> CustomModule {
  CustomModule::new(config=config.get_module("custom"))
}

///|
pub impl @ms.PromptModule for CustomModule with name(_self) -> String {
  "custom"
}

///|
pub impl @ms.PromptModule for CustomModule with is_async(_self) -> Bool {
  false
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
