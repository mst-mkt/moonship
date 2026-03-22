///|
pub struct JobsModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  number_threshold : Int
}

///|
pub fn JobsModule::default() -> JobsModule {
  {
    disabled: false,
    async_render: false,
    format: "[$symbol$number]($style) ",
    style: "bold blue",
    symbol: "✦",
    number_threshold: 2,
  }
}

///|
pub fn JobsModule::from_toml_table(table : @config.ModuleTable) -> JobsModule {
  let d = JobsModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
    number_threshold: @config.get_toml_int(table, "number_threshold").unwrap_or(
      d.number_threshold,
    ),
  }
}

///|
pub fn JobsModule::from_config(config : @config.Config) -> JobsModule {
  match config.get_raw_module("jobs") {
    Some(table) => JobsModule::from_toml_table(table)
    None => JobsModule::default()
  }
}

///|
pub impl @ms.PromptModule for JobsModule with name(_self) -> String {
  "jobs"
}

///|
pub impl @ms.PromptModule for JobsModule with is_async(self) -> Bool {
  self.async_render
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
