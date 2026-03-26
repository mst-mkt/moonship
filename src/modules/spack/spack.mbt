///|
pub struct SpackModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  truncation_length : Int
}

///|
pub fn SpackModule::default() -> SpackModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol$environment]($style) ",
    style: "blue bold",
    symbol: "🅢 ",
    truncation_length: 2147483647,
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
    truncation_length: table
    .get_int("truncation_length")
    .unwrap_or(d.truncation_length),
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

  let raw_name = basename(env)
  let name = if raw_name.length() > self.truncation_length {
    raw_name[:self.truncation_length].to_string()
  } else {
    raw_name
  }

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
  let init : (Int?, Int) = (None, 0)

  match
    path
    .iter()
    .fold(init~, fn(acc, ch) {
      let (result, i) = acc
      (if ch == '/' { Some(i) } else { result }, i + 1)
    }).0 {
    Some(last) => path[last + 1:].to_string()
    None => path
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
