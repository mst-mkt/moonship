///|
pub struct RustModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn RustModule::default() -> RustModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold red",
    symbol: "🦀 ",
    detect_files: ["Cargo.toml"],
    detect_extensions: [".rs"],
  }
}

///|
pub fn RustModule::from_table(table : @config.ModuleTable) -> RustModule {
  let d = RustModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    detect_files: table
    .get_string_array("detect_files")
    .unwrap_or(d.detect_files),
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(d.detect_extensions),
  }
}

///|
pub fn RustModule::from_config(config : @config.Config) -> RustModule {
  match config.get_raw_module("rust") {
    Some(table) => RustModule::from_table(table)
    None => RustModule::default()
  }
}

///|
pub impl @ms.PromptModule for RustModule with name(_self) -> String {
  "rust"
}

///|
pub impl @ms.PromptModule for RustModule with is_async(self) -> Bool {
  self.async_render
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
  guard not(display.is_empty()) else {
    return Skipped("could not parse rustc version")
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
fn parse_rustc_version(output : String) -> String {
  let parts = output.split(" ").map(fn(s) { s.to_string() }).collect()
  if parts.length() >= 2 {
    parts[1]
  } else {
    output
  }
}

///|
pub fn RustModule::schema() -> @config.ModuleSchema {
  let d = RustModule::default()
  {
    name: "rust",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
      {
        name: "detect_files",
        field_type: @config.FStringArray,
        default_value: d.detect_files.join(", "),
      },
      {
        name: "detect_extensions",
        field_type: @config.FStringArray,
        default_value: d.detect_extensions.join(", "),
      },
    ],
  }
}
