///|
pub struct SingularityModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn SingularityModule::default() -> SingularityModule {
  {
    disabled: false,
    async_render: false,
    format: "[$symbol\\[$env\\]]($style) ",
    style: "blue bold dimmed",
    symbol: "",
  }
}

///|
pub fn SingularityModule::from_table(
  table : @config.ModuleTable,
) -> SingularityModule {
  let d = SingularityModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
  }
}

///|
pub fn SingularityModule::from_config(
  config : @config.Config,
) -> SingularityModule {
  match config.get_raw_module("singularity") {
    Some(table) => SingularityModule::from_table(table)
    None => SingularityModule::default()
  }
}

///|
pub impl @ms.PromptModule for SingularityModule with name(_self) -> String {
  "singularity"
}

///|
pub impl @ms.PromptModule for SingularityModule with is_async(self) -> Bool {
  self.async_render
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

///|
pub fn SingularityModule::schema() -> @config.ModuleSchema {
  let d = SingularityModule::default()
  {
    name: "singularity",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
    ],
  }
}
