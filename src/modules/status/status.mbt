///|
pub struct StatusModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  success_symbol : String
  not_executable_symbol : String
  not_found_symbol : String
  map_symbol : Bool
}

///|
pub fn StatusModule::default() -> StatusModule {
  {
    disabled: true,
    async_render: false,
    format: "[$symbol$status]($style) ",
    style: "bold red",
    symbol: "❌",
    success_symbol: "",
    not_executable_symbol: "🚫",
    not_found_symbol: "🔍",
    map_symbol: false,
  }
}

///|
pub fn StatusModule::from_toml_table(
  table : @config.ModuleTable,
) -> StatusModule {
  let d = StatusModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
    success_symbol: @config.get_toml_string(table, "success_symbol").unwrap_or(
      d.success_symbol,
    ),
    not_executable_symbol: @config.get_toml_string(
      table, "not_executable_symbol",
    ).unwrap_or(d.not_executable_symbol),
    not_found_symbol: @config.get_toml_string(table, "not_found_symbol").unwrap_or(
      d.not_found_symbol,
    ),
    map_symbol: @config.get_toml_bool(table, "map_symbol").unwrap_or(
      d.map_symbol,
    ),
  }
}

///|
pub fn StatusModule::from_config(config : @config.Config) -> StatusModule {
  match config.get_raw_module("status") {
    Some(table) => StatusModule::from_toml_table(table)
    None => StatusModule::default()
  }
}

///|
pub impl @ms.PromptModule for StatusModule with name(_self) -> String {
  "status"
}

///|
pub impl @ms.PromptModule for StatusModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for StatusModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard ctx.status != 0 || not(self.success_symbol.is_empty()) else {
    return Skipped("success exit code")
  }

  let status_str = ctx.status.to_string()
  let symbol = if ctx.status == 0 {
    self.success_symbol
  } else if self.map_symbol {
    match ctx.status {
      126 => self.not_executable_symbol
      127 => self.not_found_symbol
      _ => self.symbol
    }
  } else {
    self.symbol
  }

  let vars : Map[String, String] = {
    "status": status_str,
    "int": status_str,
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
