///|
pub struct VcshModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn VcshModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("vcsh"),
) -> VcshModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default=""),
  }
}

///|
pub fn VcshModule::from_config(config : @config.Config) -> VcshModule {
  VcshModule::new(config=config.get_module("vcsh"))
}

///|
pub impl @ms.PromptModule for VcshModule with name(_self) -> String {
  "vcsh"
}

///|
pub impl @ms.PromptModule for VcshModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let repo = @sys.get_env_var("VCSH_REPO_NAME").unwrap_or("")
  guard not(repo.is_empty()) else { return Skipped("not in vcsh repo") }

  let vars : Map[String, String] = {
    "repo": repo,
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
