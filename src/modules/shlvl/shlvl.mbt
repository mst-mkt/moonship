///|
pub struct ShlvlModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  threshold : Int
  repeat : Bool
  repeat_offset : Int
}

///|
pub fn ShlvlModule::default() -> ShlvlModule {
  {
    disabled: true,
    async_render: false,
    format: "[$symbol$shlvl]($style) ",
    style: "bold yellow",
    symbol: "↕️  ",
    threshold: 2,
    repeat: false,
    repeat_offset: 0,
  }
}

///|
pub fn ShlvlModule::from_toml_table(table : @config.ModuleTable) -> ShlvlModule {
  let d = ShlvlModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
    threshold: @config.get_toml_int(table, "threshold").unwrap_or(d.threshold),
    repeat: @config.get_toml_bool(table, "repeat").unwrap_or(d.repeat),
    repeat_offset: @config.get_toml_int(table, "repeat_offset").unwrap_or(
      d.repeat_offset,
    ),
  }
}

///|
pub fn ShlvlModule::from_config(config : @config.Config) -> ShlvlModule {
  match config.get_raw_module("shlvl") {
    Some(table) => ShlvlModule::from_toml_table(table)
    None => ShlvlModule::default()
  }
}

///|
pub impl @ms.PromptModule for ShlvlModule with name(_self) -> String {
  "shlvl"
}

///|
pub impl @ms.PromptModule for ShlvlModule with is_async(self) -> Bool {
  self.async_render
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

///|
pub fn ShlvlModule::schema() -> @config.ModuleSchema {
  let d = ShlvlModule::default()
  {
    name: "shlvl",
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
        name: "repeat",
        field_type: @config.FBool,
        default_value: d.repeat.to_string(),
      },
      {
        name: "repeat_offset",
        field_type: @config.FInt,
        default_value: d.repeat_offset.to_string(),
      },
    ],
  }
}
