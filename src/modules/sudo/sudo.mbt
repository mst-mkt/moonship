///|
pub struct SudoModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn SudoModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("sudo"),
) -> SudoModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🧙 "),
  }
}

///|
pub fn SudoModule::from_config(config : @config.Config) -> SudoModule {
  SudoModule::new(config=config.get_module("sudo"))
}

///|
pub impl @ms.PromptModule for SudoModule with name(_self) -> String {
  "sudo"
}

///|
pub impl @ms.PromptModule for SudoModule with is_async(_self) -> Bool {
  false
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
