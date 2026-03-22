///|
pub struct RedModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn RedModule::default() -> RedModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "red bold",
    symbol: "🔺 ",
    detect_files: [],
    detect_extensions: [".red", ".reds"],
  }
}

///|
pub fn RedModule::from_toml_table(table : @config.ModuleTable) -> RedModule {
  let d = RedModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
    detect_files: @config.get_toml_string_array(table, "detect_files").unwrap_or(
      d.detect_files,
    ),
    detect_extensions: @config.get_toml_string_array(table, "detect_extensions").unwrap_or(
      d.detect_extensions,
    ),
  }
}

///|
pub fn RedModule::from_config(config : @config.Config) -> RedModule {
  match config.get_raw_module("red") {
    Some(table) => RedModule::from_toml_table(table)
    None => RedModule::default()
  }
}

///|
pub impl @ms.PromptModule for RedModule with name(_self) -> String {
  "red"
}

///|
pub impl @ms.PromptModule for RedModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for RedModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Red project detected")
  }

  let output = @exec.exec_cmd("red", ["--version"])
  guard not(output.is_empty()) else { return Skipped("red not found") }

  let display = parse_red_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse red version")
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
fn parse_red_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() == 0 {
    return ""
  }

  parts[parts.length() - 1].to_string()
}
