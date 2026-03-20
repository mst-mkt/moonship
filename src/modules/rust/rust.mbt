///|
pub struct RustModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn RustModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("rust"),
) -> RustModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🦀 "),
    detect_files: ["Cargo.toml"],
    detect_extensions: [".rs"],
  }
}

///|
pub fn RustModule::from_config(config : @config.Config) -> RustModule {
  RustModule::new(config=config.get_module("rust"))
}

///|
pub impl @ms.PromptModule for RustModule with name(_self) -> String {
  "rust"
}

///|
pub impl @ms.PromptModule for RustModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Rust project detected")
  }

  let version = @exec.exec_cmd("rustc", ["--version"])
  guard not(version.is_empty()) else { return Skipped("rustc not found") }

  let display = parse_rustc_version(version)
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
fn parse_rustc_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() >= 2 {
    parts[1].to_string()
  } else {
    output
  }
}
