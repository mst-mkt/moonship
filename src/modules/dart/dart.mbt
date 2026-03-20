///|
pub struct DartModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn DartModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("dart"),
) -> DartModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🎯 "),
    detect_files: ["pubspec.yaml", "pubspec.yml", "pubspec.lock"],
    detect_extensions: [".dart"],
  }
}

///|
pub fn DartModule::from_config(config : @config.Config) -> DartModule {
  DartModule::new(config=config.get_module("dart"))
}

///|
pub impl @ms.PromptModule for DartModule with name(_self) -> String {
  "dart"
}

///|
pub impl @ms.PromptModule for DartModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Dart project detected")
  }

  let output = @exec.exec_cmd("dart", ["--version"])
  guard not(output.is_empty()) else { return Skipped("dart not found") }

  let display = parse_dart_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse dart version")
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
fn parse_dart_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() >= 4 {
    parts[3].to_string()
  } else {
    ""
  }
}
