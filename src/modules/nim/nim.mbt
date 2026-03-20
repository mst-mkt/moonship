///|
pub struct NimModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn NimModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("nim"),
) -> NimModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="👑 "),
    detect_files: ["nim.cfg"],
    detect_extensions: [".nim", ".nims", ".nimble"],
  }
}

///|
pub fn NimModule::from_config(config : @config.Config) -> NimModule {
  NimModule::new(config=config.get_module("nim"))
}

///|
pub impl @ms.PromptModule for NimModule with name(_self) -> String {
  "nim"
}

///|
pub impl @ms.PromptModule for NimModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Nim project detected")
  }

  let output = @exec.exec_cmd("nim", ["--version"])
  guard not(output.is_empty()) else { return Skipped("nim not found") }

  let display = parse_nim_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse nim version")
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
fn parse_nim_version(output : String) -> String {
  let parts = output.split(" ").collect()

  for i = 0; i < parts.length(); i = i + 1 {
    let s = parts[i].to_string()
    if not(s.is_empty()) && is_digit_or_dot(s) {
      return s
    }
  }

  ""
}

///|
fn is_digit_or_dot(s : String) -> Bool {
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i].unsafe_to_char()
    if not((c >= '0' && c <= '9') || c == '.') {
      return false
    }
  }

  true
}
