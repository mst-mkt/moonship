///|
pub struct NixShellModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  impure_msg : String
  pure_msg : String
  unknown_msg : String
  heuristic : Bool
}

///|
pub fn NixShellModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "nix_shell",
  ),
) -> NixShellModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="❄️  "),
    impure_msg: config.get_prop("impure_msg", default="impure"),
    pure_msg: config.get_prop("pure_msg", default="pure"),
    unknown_msg: config.get_prop("unknown_msg", default=""),
    heuristic: config.get_prop("heuristic") == "true",
  }
}

///|
pub fn NixShellModule::from_config(config : @config.Config) -> NixShellModule {
  NixShellModule::new(config=config.get_module("nix_shell"))
}

///|
pub impl @ms.PromptModule for NixShellModule with name(_self) -> String {
  "nix_shell"
}

///|
pub impl @ms.PromptModule for NixShellModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let in_nix = @sys.get_env_var("IN_NIX_SHELL").unwrap_or("")
  let state = if in_nix == "pure" {
    self.pure_msg
  } else if in_nix == "impure" {
    self.impure_msg
  } else if self.heuristic && is_nix_in_path() {
    self.unknown_msg
  } else {
    return Skipped("not in nix shell")
  }

  let name = @sys.get_env_var("name").unwrap_or("")
  let vars : Map[String, String] = {
    "symbol": self.symbol,
    "state": state,
    "style": self.style,
  }

  if not(name.is_empty()) {
    vars["name"] = name
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn is_nix_in_path() -> Bool {
  let path = @sys.get_env_var("PATH").unwrap_or("")
  path.contains("/nix/store")
}
