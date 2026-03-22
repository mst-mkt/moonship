///|
pub struct CondaModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  ignore_base : Bool
}

///|
pub fn CondaModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("conda"),
) -> CondaModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🅒 "),
    ignore_base: config.get_prop("ignore_base", default="true") != "false",
  }
}

///|
pub fn CondaModule::from_config(config : @config.Config) -> CondaModule {
  CondaModule::new(config=config.get_module("conda"))
}

///|
pub impl @ms.PromptModule for CondaModule with name(_self) -> String {
  "conda"
}

///|
pub impl @ms.PromptModule for CondaModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for CondaModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let env = @sys.get_env_var("CONDA_DEFAULT_ENV").unwrap_or("")
  guard not(env.is_empty()) else { return Skipped("not in conda env") }
  guard not(self.ignore_base && env == "base") else {
    return Skipped("ignoring base env")
  }

  let name = basename(env)
  let vars : Map[String, String] = {
    "environment": name,
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
fn basename(path : String) -> String {
  let mut last = -1

  for i = 0; i < path.length(); i = i + 1 {
    if path[i] == '/' {
      last = i
    }
  }

  if last >= 0 {
    path[last + 1:].to_string()
  } else {
    path
  }
}
