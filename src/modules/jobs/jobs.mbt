///|
pub struct JobsModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  number_threshold : Int
}

///|
pub fn JobsModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("jobs"),
) -> JobsModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="✦"),
    number_threshold: config.get_int_prop("number_threshold", default=2),
  }
}

///|
pub fn JobsModule::from_config(config : @config.Config) -> JobsModule {
  JobsModule::new(config=config.get_module("jobs"))
}

///|
pub impl @ms.PromptModule for JobsModule with name(_self) -> String {
  "jobs"
}

///|
pub impl @ms.PromptModule for JobsModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for JobsModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard ctx.jobs > 0 else { return Skipped("no background jobs") }

  let number = if ctx.jobs >= self.number_threshold {
    ctx.jobs.to_string()
  } else {
    ""
  }

  let vars : Map[String, String] = {
    "symbol": self.symbol,
    "number": number,
    "style": self.style,
  }
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}
