///|
pub struct PijulChannelModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn PijulChannelModule::default() -> PijulChannelModule {
  {
    disabled: true,
    async_render: false,
    format: "on [$symbol$channel]($style) ",
    style: "bold purple",
    symbol: " ",
  }
}

///|
pub fn PijulChannelModule::from_toml_table(
  table : @config.ModuleTable,
) -> PijulChannelModule {
  let d = PijulChannelModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
  }
}

///|
pub fn PijulChannelModule::from_config(
  config : @config.Config,
) -> PijulChannelModule {
  match config.get_raw_module("pijul_channel") {
    Some(table) => PijulChannelModule::from_toml_table(table)
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

  let vars : Map[String, String] = {
    "channel": channel,
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
  let lines = output.split("\n").collect()

  for line in lines {
    let s = line.to_string()
    if s.has_prefix("* ") {
      return s[2:].to_string()
    }
  }

  ""
}
