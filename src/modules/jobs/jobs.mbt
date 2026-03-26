///|
pub struct JobsModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  threshold : Int
  symbol_threshold : Int
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
    threshold: 1,
    symbol_threshold: 1,
    number_threshold: 2,
  }
}

///|
pub fn JobsModule::from_table(table : @config.ModuleTable) -> JobsModule {
  let d = JobsModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    threshold: table.get_int("threshold").unwrap_or(d.threshold),
    symbol_threshold: table
    .get_int("symbol_threshold")
    .unwrap_or(d.symbol_threshold),
    number_threshold: table
    .get_int("number_threshold")
    .unwrap_or(d.number_threshold),
  }
}

///|
pub fn JobsModule::from_config(config : @config.Config) -> JobsModule {
  match config.get_raw_module("jobs") {
    Some(table) => JobsModule::from_table(table)
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
  guard ctx.jobs >= self.threshold else { return Skipped("below threshold") }

  let number = if ctx.jobs >= self.number_threshold {
    ctx.jobs.to_string()
  } else {
    ""
  }

  let symbol = if ctx.jobs >= self.symbol_threshold { self.symbol } else { "" }

  let vars : Map[String, String] = {
    "symbol": symbol,
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

///|
pub fn JobsModule::schema() -> @config.ModuleSchema {
  let d = JobsModule::default()
  {
    name: "jobs",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
      {
        name: "threshold",
        field_type: @config.FInt,
        default_value: d.threshold.to_string(),
      },
      {
        name: "symbol_threshold",
        field_type: @config.FInt,
        default_value: d.symbol_threshold.to_string(),
      },
      {
        name: "number_threshold",
        field_type: @config.FInt,
        default_value: d.number_threshold.to_string(),
      },
    ],
  }
}
