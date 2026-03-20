///|
pub struct JuliaModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn JuliaModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("julia"),
) -> JuliaModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="ஃ "),
    detect_files: ["Project.toml", "Manifest.toml"],
    detect_extensions: [".jl"],
  }
}

///|
pub fn JuliaModule::from_config(config : @config.Config) -> JuliaModule {
  JuliaModule::new(config=config.get_module("julia"))
}

///|
pub impl @ms.PromptModule for JuliaModule with name(_self) -> String {
  "julia"
}

///|
pub impl @ms.PromptModule for JuliaModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Julia project detected")
  }

  let output = @exec.exec_cmd("julia", ["--version"])
  guard not(output.is_empty()) else { return Skipped("julia not found") }

  let display = parse_julia_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse julia version")
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
fn parse_julia_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() >= 3 {
    parts[2].to_string()
  } else {
    ""
  }
}
