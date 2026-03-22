///|
pub struct SpackModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn SpackModule::default() -> SpackModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol$environment]($style) ",
    style: "blue bold",
    symbol: "🅢 ",
  }
}

///|
pub fn SpackModule::from_table(table : @config.ModuleTable) -> SpackModule {
  let d = SpackModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
  }
}

///|
pub fn SpackModule::from_config(config : @config.Config) -> SpackModule {
  match config.get_raw_module("spack") {
    Some(table) => SpackModule::from_table(table)
    None => SpackModule::default()
  }
}

///|
pub impl @ms.PromptModule for SpackModule with name(_self) -> String {
  "spack"
}

///|
pub impl @ms.PromptModule for SpackModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for SpackModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let env = @sys.get_env_var("SPACK_ENV").unwrap_or("")
  guard not(env.is_empty()) else { return Skipped("not in spack env") }

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

///|
pub fn SpackModule::schema() -> @config.ModuleSchema {
  let d = SpackModule::default()
  {
    name: "spack",
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
