///|
pub struct CrystalModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn CrystalModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "crystal",
  ),
) -> CrystalModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🔮 "),
    detect_files: ["shard.yml"],
    detect_extensions: [".cr"],
  }
}

///|
pub fn CrystalModule::from_config(config : @config.Config) -> CrystalModule {
  CrystalModule::new(config=config.get_module("crystal"))
}

///|
pub impl @ms.PromptModule for CrystalModule with name(_self) -> String {
  "crystal"
}

///|
pub impl @ms.PromptModule for CrystalModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Crystal project detected")
  }

  let output = @exec.exec_cmd("crystal", ["--version"])
  guard not(output.is_empty()) else { return Skipped("crystal not found") }

  let display = parse_crystal_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse crystal version")
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
fn parse_crystal_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() >= 2 {
    parts[1].to_string()
  } else {
    ""
  }
}
