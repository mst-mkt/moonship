///|
pub struct KotlinModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  kotlin_binary : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn KotlinModule::default() -> KotlinModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold blue",
    symbol: "🅺 ",
    kotlin_binary: "kotlin",
    detect_files: [],
    detect_extensions: [".kt", ".kts"],
  }
}

///|
pub fn KotlinModule::from_toml_table(
  table : @config.ModuleTable,
) -> KotlinModule {
  let d = KotlinModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
    kotlin_binary: @config.get_toml_string(table, "kotlin_binary").unwrap_or(
      d.kotlin_binary,
    ),
    detect_files: @config.get_toml_string_array(table, "detect_files").unwrap_or(
      d.detect_files,
    ),
    detect_extensions: @config.get_toml_string_array(table, "detect_extensions").unwrap_or(
      d.detect_extensions,
    ),
  }
}

///|
pub fn KotlinModule::from_config(config : @config.Config) -> KotlinModule {
  match config.get_raw_module("kotlin") {
    Some(table) => KotlinModule::from_toml_table(table)
    None => KotlinModule::default()
  }
}

///|
pub impl @ms.PromptModule for KotlinModule with name(_self) -> String {
  "kotlin"
}

///|
pub impl @ms.PromptModule for KotlinModule with is_async(self) -> Bool {
  self.async_render
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
