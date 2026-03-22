///|
pub struct GuixShellModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn GuixShellModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "guix_shell",
  ),
) -> GuixShellModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🐃 "),
  }
}

///|
pub fn GuixShellModule::from_config(config : @config.Config) -> GuixShellModule {
  GuixShellModule::new(config=config.get_module("guix_shell"))
}

///|
pub impl @ms.PromptModule for GuixShellModule with name(_self) -> String {
  "guix_shell"
}

///|
pub impl @ms.PromptModule for GuixShellModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for GuixShellModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let env = @sys.get_env_var("GUIX_ENVIRONMENT").unwrap_or("")
  guard not(env.is_empty()) else { return Skipped("not in guix shell") }

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
