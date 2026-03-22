///|
pub struct RedModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn RedModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("red"),
) -> RedModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🔺 "),
    detect_files: [],
    detect_extensions: [".red", ".reds"],
  }
}

///|
pub fn RedModule::from_config(config : @config.Config) -> RedModule {
  RedModule::new(config=config.get_module("red"))
}

///|
pub impl @ms.PromptModule for RedModule with name(_self) -> String {
  "red"
}

///|
pub impl @ms.PromptModule for RedModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for RedModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Red project detected")
  }

  let output = @exec.exec_cmd("red", ["--version"])
  guard not(output.is_empty()) else { return Skipped("red not found") }

  let display = parse_red_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse red version")
  }

  let vars : Map[String, String] = {
    "version": @exec.add_v_prefix(display),
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
fn parse_red_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() == 0 {
    return ""
  }

  parts[parts.length() - 1].to_string()
}
