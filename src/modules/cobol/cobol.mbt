///|
pub struct CobolModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn CobolModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("cobol"),
) -> CobolModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="⚙️ "),
    detect_files: [],
    detect_extensions: [".cbl", ".cob", ".CBL", ".COB"],
  }
}

///|
pub fn CobolModule::from_config(config : @config.Config) -> CobolModule {
  CobolModule::new(config=config.get_module("cobol"))
}

///|
pub impl @ms.PromptModule for CobolModule with name(_self) -> String {
  "cobol"
}

///|
pub impl @ms.PromptModule for CobolModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for CobolModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no COBOL project detected")
  }

  let output = @exec.exec_cmd("cobc", ["-version"])
  guard not(output.is_empty()) else { return Skipped("cobc not found") }

  let display = parse_cobol_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse cobol version")
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
fn parse_cobol_version(output : String) -> String {
  let parts = output.split(" ").collect()

  for i = 0; i < parts.length(); i = i + 1 {
    let s = parts[i].to_string()
    if not(s.is_empty()) &&
      s[0].unsafe_to_char() >= '0' &&
      s[0].unsafe_to_char() <= '9' {
      return extract_version_digits(s)
    }
  }

  ""
}

///|
fn extract_version_digits(s : String) -> String {
  let buf = StringBuilder::new()

  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i].unsafe_to_char()
    if (c >= '0' && c <= '9') || c == '.' {
      buf.write_char(c)
    } else {
      break
    }
  }

  buf.to_string()
}
