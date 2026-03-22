///|
pub struct PijulChannelModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn PijulChannelModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "pijul_channel",
  ),
) -> PijulChannelModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default=" "),
  }
}

///|
pub fn PijulChannelModule::from_config(
  config : @config.Config,
) -> PijulChannelModule {
  PijulChannelModule::new(config=config.get_module("pijul_channel"))
}

///|
pub impl @ms.PromptModule for PijulChannelModule with name(_self) -> String {
  "pijul_channel"
}

///|
pub impl @ms.PromptModule for PijulChannelModule with is_async(_self) -> Bool {
  false
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
