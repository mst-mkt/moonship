///|
pub struct VlangModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn VlangModule::default() -> VlangModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "blue bold",
    symbol: "V ",
    detect_files: ["v.mod", "vpkg.json", ".vpkg-lock.json"],
    detect_extensions: [".v"],
  }
}

///|
pub fn VlangModule::from_toml_table(table : @config.ModuleTable) -> VlangModule {
  let d = VlangModule::default()
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
pub fn VlangModule::from_config(config : @config.Config) -> VlangModule {
  match config.get_raw_module("vlang") {
    Some(table) => VlangModule::from_toml_table(table)
    None => VlangModule::default()
  }
}

///|
pub impl @ms.PromptModule for VlangModule with name(_self) -> String {
  "vlang"
}

///|
pub impl @ms.PromptModule for VlangModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for VlangModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no V project detected")
  }

  let output = @exec.exec_cmd("v", ["version"])
  guard not(output.is_empty()) else { return Skipped("v not found") }

  let parts = output.split(" ").collect()
  guard parts.length() >= 1 else { return Skipped("could not parse V version") }

  let version = parts[parts.length() - 1].to_string()
  guard not(version.is_empty()) else {
    return Skipped("could not parse V version")
  }

  let vars : Map[String, String] = {
    "version": @exec.add_v_prefix(version),
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
