///|
pub struct SingularityModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn SingularityModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "singularity",
  ),
) -> SingularityModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default=""),
  }
}

///|
pub fn SingularityModule::from_config(
  config : @config.Config,
) -> SingularityModule {
  SingularityModule::new(config=config.get_module("singularity"))
}

///|
pub impl @ms.PromptModule for SingularityModule with name(_self) -> String {
  "singularity"
}

///|
pub impl @ms.PromptModule for SingularityModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for SingularityModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let env = @sys.get_env_var("SINGULARITY_NAME").unwrap_or("")
  guard not(env.is_empty()) else {
    return Skipped("not in singularity container")
  }

  let vars : Map[String, String] = {
    "env": env,
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
