///|
pub struct PijulChannelModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  truncation_length : Int
  truncation_symbol : String
}

///|
pub fn PijulChannelModule::default() -> PijulChannelModule {
  {
    disabled: true,
    async_render: false,
    format: "on [$symbol$channel]($style) ",
    style: "bold purple",
    symbol: " ",
    truncation_length: 2147483647,
    truncation_symbol: "…",
  }
}

///|
pub fn PijulChannelModule::from_table(
  table : @config.ModuleTable,
) -> PijulChannelModule {
  let d = PijulChannelModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    truncation_length: table
    .get_int("truncation_length")
    .unwrap_or(d.truncation_length),
    truncation_symbol: table
    .get_string("truncation_symbol")
    .unwrap_or(d.truncation_symbol),
  }
}

///|
pub fn PijulChannelModule::from_config(
  config : @config.Config,
) -> PijulChannelModule {
  match config.get_raw_module("pijul_channel") {
    Some(table) => PijulChannelModule::from_table(table)
    None => PijulChannelModule::default()
  }
}

///|
pub impl @ms.PromptModule for PijulChannelModule with name(_self) -> String {
  "pijul_channel"
}

///|
pub impl @ms.PromptModule for PijulChannelModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for PijulChannelModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @fs.path_exists(ctx.cwd + "/.pijul") else {
    return Skipped("not in pijul repo")
  }

  let output = @exec.exec_cmd_full("pijul", ["channel"])
  guard not(output.is_empty()) else { return Skipped("pijul not found") }

  let channel = parse_pijul_channel(output)
  guard not(channel.is_empty()) else {
    return Skipped("could not parse pijul channel")
  }

  let display = if channel.length() > self.truncation_length {
    channel[:self.truncation_length].to_string() + self.truncation_symbol
  } else {
    channel
  }

  let vars : Map[String, String] = {
    "channel": display,
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
fn parse_pijul_channel(output : String) -> String {
  output
  .split("\n")
  .map(fn(s) { s.to_string() })
  .find_first(fn(s) { s.has_prefix("* ") })
  .map(fn(s) { s[2:].to_string() })
  .unwrap_or("")
}

///|
pub fn PijulChannelModule::schema() -> @config.ModuleSchema {
  let d = PijulChannelModule::default()
  {
    name: "pijul_channel",
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
        name: "truncation_length",
        field_type: @config.FInt,
        default_value: d.truncation_length.to_string(),
      },
      {
        name: "truncation_symbol",
        field_type: @config.FString,
        default_value: d.truncation_symbol,
      },
    ],
  }
}
