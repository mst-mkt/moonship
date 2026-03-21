///|
pub struct SwiftModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn SwiftModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("swift"),
) -> SwiftModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🐦 "),
    detect_files: ["Package.swift"],
    detect_extensions: [".swift"],
  }
}

///|
pub fn SwiftModule::from_config(config : @config.Config) -> SwiftModule {
  SwiftModule::new(config=config.get_module("swift"))
}

///|
pub impl @ms.PromptModule for SwiftModule with name(_self) -> String {
  "swift"
}

///|
pub impl @ms.PromptModule for SwiftModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Swift project detected")
  }

  let output = @exec.exec_cmd("swift", ["--version"])
  guard not(output.is_empty()) else { return Skipped("swift not found") }

  let display = parse_swift_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse swift version")
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
fn parse_swift_version(output : String) -> String {
  let parts = output.split(" ").collect()
  let mut version_next = false

  for i = 0; i < parts.length(); i = i + 1 {
    let s = parts[i].to_string()
    if version_next {
      return s
    }
    if s == "version" {
      version_next = true
    }
  }

  ""
}
