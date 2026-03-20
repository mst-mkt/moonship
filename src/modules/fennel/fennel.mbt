///|
pub struct FennelModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn FennelModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "fennel",
  ),
) -> FennelModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🧅 "),
    detect_files: [],
    detect_extensions: [".fnl"],
  }
}

///|
pub fn FennelModule::from_config(config : @config.Config) -> FennelModule {
  FennelModule::new(config=config.get_module("fennel"))
}

///|
pub impl @ms.PromptModule for FennelModule with name(_self) -> String {
  "fennel"
}

///|
pub impl @ms.PromptModule for FennelModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Fennel project detected")
  }

  let output = @exec.exec_cmd("fennel", ["--version"])
  guard not(output.is_empty()) else { return Skipped("fennel not found") }

  let display = parse_fennel_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse fennel version")
  }

  let vars : Map[String, String] = {
    "version": display,
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
fn parse_fennel_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() == 0 {
    return ""
  }

  parts[parts.length() - 1].to_string()
}
