///|
pub struct MoonbitModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn MoonbitModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "moonbit",
  ),
) -> MoonbitModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🐰 "),
    detect_files: ["moon.mod.json", "moon.pkg.json"],
    detect_extensions: [".mbt"],
  }
}

///|
pub fn MoonbitModule::from_config(config : @config.Config) -> MoonbitModule {
  MoonbitModule::new(config=config.get_module("moonbit"))
}

///|
pub impl @ms.PromptModule for MoonbitModule with name(_self) -> String {
  "moonbit"
}

///|
pub impl @ms.PromptModule for MoonbitModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no MoonBit project detected")
  }

  let output = @exec.exec_cmd("moon", ["version"])
  guard not(output.is_empty()) else { return Skipped("moon not found") }

  let display = parse_moon_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse moon version")
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
fn parse_moon_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() >= 2 {
    parts[1].to_string()
  } else {
    ""
  }
}
