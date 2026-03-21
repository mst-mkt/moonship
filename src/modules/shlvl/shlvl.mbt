///|
pub struct ShlvlModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  threshold : Int
  repeat : Bool
  repeat_offset : Int
}

///|
pub fn ShlvlModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("shlvl"),
) -> ShlvlModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="↕️  "),
    threshold: config.get_int_prop("threshold", default=2),
    repeat: config.get_prop("repeat") == "true",
    repeat_offset: config.get_int_prop("repeat_offset", default=0),
  }
}

///|
pub fn ShlvlModule::from_config(config : @config.Config) -> ShlvlModule {
  ShlvlModule::new(config=config.get_module("shlvl"))
}

///|
pub impl @ms.PromptModule for ShlvlModule with name(_self) -> String {
  "shlvl"
}

///|
pub impl @ms.PromptModule for ShlvlModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard ctx.shlvl >= self.threshold else {
    return Skipped("shlvl below threshold")
  }

  let symbol = if self.repeat {
    let count = ctx.shlvl - self.repeat_offset
    guard count > 0 else { return Skipped("shlvl repeat count zero") }

    let buf = StringBuilder::new()
    for i = 0; i < count; i = i + 1 {
      buf.write_string(self.symbol)
    }
    buf.to_string()
  } else {
    self.symbol
  }

  let vars : Map[String, String] = {
    "shlvl": ctx.shlvl.to_string(),
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
