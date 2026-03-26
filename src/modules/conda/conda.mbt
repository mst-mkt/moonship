///|
pub struct CondaModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  truncation_length : Int
  ignore_base : Bool
}

///|
pub fn CondaModule::default() -> CondaModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol$environment]($style) ",
    style: "green bold",
    symbol: "🅒 ",
    truncation_length: 2147483647,
    ignore_base: true,
  }
}

///|
pub fn CondaModule::from_table(table : @config.ModuleTable) -> CondaModule {
  let d = CondaModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    truncation_length: table
    .get_int("truncation_length")
    .unwrap_or(d.truncation_length),
    ignore_base: table.get_bool("ignore_base").unwrap_or(d.ignore_base),
  }
}

///|
pub fn CondaModule::from_config(config : @config.Config) -> CondaModule {
  match config.get_raw_module("conda") {
    Some(table) => CondaModule::from_table(table)
    None => CondaModule::default()
  }
}

///|
pub impl @ms.PromptModule for CondaModule with name(_self) -> String {
  "conda"
}

///|
pub impl @ms.PromptModule for CondaModule with is_async(self) -> Bool {
  self.async_render
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
pub fn CondaModule::schema() -> @config.ModuleSchema {
  let d = CondaModule::default()
  {
    name: "conda",
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
        name: "ignore_base",
        field_type: @config.FBool,
        default_value: d.ignore_base.to_string(),
      },
    ],
  }
}
