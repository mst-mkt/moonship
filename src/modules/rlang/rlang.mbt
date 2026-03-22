///|
pub struct RlangModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_folders : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn RlangModule::default() -> RlangModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "blue bold",
    symbol: "📐 ",
    detect_files: ["DESCRIPTION"],
    detect_folders: [".Rproj.user"],
    detect_extensions: [".R", ".Rd", ".Rmd", ".Rproj", ".Rsx"],
  }
}

///|
pub fn RlangModule::from_toml_table(table : @config.ModuleTable) -> RlangModule {
  let d = RlangModule::default()
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
    detect_folders: @config.get_toml_string_array(table, "detect_folders").unwrap_or(
      d.detect_folders,
    ),
    detect_extensions: @config.get_toml_string_array(table, "detect_extensions").unwrap_or(
      d.detect_extensions,
    ),
  }
}

///|
pub fn RlangModule::from_config(config : @config.Config) -> RlangModule {
  match config.get_raw_module("rlang") {
    Some(table) => RlangModule::from_toml_table(table)
    None => RlangModule::default()
  }
}

///|
pub impl @ms.PromptModule for RlangModule with name(_self) -> String {
  "rlang"
}

///|
pub impl @ms.PromptModule for RlangModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for RlangModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(
    ctx.cwd,
    self.detect_files,
    self.detect_extensions,
    folders=self.detect_folders,
  ) else {
    return Skipped("no R project detected")
  }

  let output = @exec.exec_cmd("R", ["--version"])
  guard not(output.is_empty()) else { return Skipped("R not found") }

  let parts = output.split(" ").collect()
  guard parts.length() >= 3 else { return Skipped("could not parse R version") }

  let version = parts[2].to_string()
  guard not(version.is_empty()) else {
    return Skipped("could not parse R version")
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
