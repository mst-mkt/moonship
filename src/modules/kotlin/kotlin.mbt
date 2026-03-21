///|
pub struct KotlinModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  kotlin_binary : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn KotlinModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "kotlin",
  ),
) -> KotlinModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🅺 "),
    kotlin_binary: config.get_prop("kotlin_binary", default="kotlin"),
    detect_files: [],
    detect_extensions: [".kt", ".kts"],
  }
}

///|
pub fn KotlinModule::from_config(config : @config.Config) -> KotlinModule {
  KotlinModule::new(config=config.get_module("kotlin"))
}

///|
pub impl @ms.PromptModule for KotlinModule with name(_self) -> String {
  "kotlin"
}

///|
pub impl @ms.PromptModule for KotlinModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Kotlin project detected")
  }

  let output = @exec.exec_cmd(self.kotlin_binary, ["-version"])
  guard not(output.is_empty()) else { return Skipped("kotlin not found") }

  let display = parse_kotlin_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse kotlin version")
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
fn parse_kotlin_version(output : String) -> String {
  let parts = output.split(" ").collect()

  for i = 0; i < parts.length(); i = i + 1 {
    let s = parts[i].to_string()
    if not(s.is_empty()) &&
      s[0].unsafe_to_char() >= '0' &&
      s[0].unsafe_to_char() <= '9' {
      return extract_digits_and_dots(s)
    }
  }

  ""
}

///|
fn extract_digits_and_dots(s : String) -> String {
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
