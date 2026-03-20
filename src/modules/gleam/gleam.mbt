///|
pub struct GleamModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn GleamModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("gleam"),
) -> GleamModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="⭐ "),
    detect_files: ["gleam.toml"],
    detect_extensions: [".gleam"],
  }
}

///|
pub fn GleamModule::from_config(config : @config.Config) -> GleamModule {
  GleamModule::new(config=config.get_module("gleam"))
}

///|
pub impl @ms.PromptModule for GleamModule with name(_self) -> String {
  "gleam"
}

///|
pub impl @ms.PromptModule for GleamModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Gleam project detected")
  }

  let output = @exec.exec_cmd("gleam", ["--version"])
  guard not(output.is_empty()) else { return Skipped("gleam not found") }

  let display = parse_gleam_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse gleam version")
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
fn parse_gleam_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() == 0 {
    return ""
  }

  parts[parts.length() - 1].to_string()
}
