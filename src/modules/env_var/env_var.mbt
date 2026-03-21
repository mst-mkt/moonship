///|
pub struct EnvVarModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  variable : String
  default_value : String
}

///|
pub fn EnvVarModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "env_var",
  ),
) -> EnvVarModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default=""),
    variable: config.get_prop("variable", default=""),
    default_value: config.get_prop("default", default=""),
  }
}

///|
pub fn EnvVarModule::from_config(config : @config.Config) -> EnvVarModule {
  EnvVarModule::new(config=config.get_module("env_var"))
}

///|
pub impl @ms.PromptModule for EnvVarModule with name(_self) -> String {
  "env_var"
}

///|
pub impl @ms.PromptModule for EnvVarModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard not(self.variable.is_empty()) else {
    return Skipped("no variable configured")
  }

  let env_value = @sys.get_env_var(self.variable).unwrap_or("")
  let display = if not(env_value.is_empty()) {
    env_value
  } else if not(self.default_value.is_empty()) {
    self.default_value
  } else {
    return Skipped("env var not set")
  }

  let vars : Map[String, String] = {
    "env_value": display,
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
