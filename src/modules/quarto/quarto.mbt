///|
pub struct QuartoModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn QuartoModule::default() -> QuartoModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold #75AADB",
    symbol: "⨁ ",
    detect_files: ["_quarto.yml"],
    detect_extensions: [".qmd"],
  }
}

///|
pub fn QuartoModule::from_toml_table(
  table : @config.ModuleTable,
) -> QuartoModule {
  let d = QuartoModule::default()
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
pub fn QuartoModule::from_config(config : @config.Config) -> QuartoModule {
  match config.get_raw_module("quarto") {
    Some(table) => QuartoModule::from_toml_table(table)
    None => QuartoModule::default()
  }
}

///|
pub impl @ms.PromptModule for QuartoModule with name(_self) -> String {
  "quarto"
}

///|
pub impl @ms.PromptModule for QuartoModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for QuartoModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Quarto project detected")
  }

  let version = @exec.exec_cmd("quarto", ["--version"])
  guard not(version.is_empty()) else { return Skipped("quarto not found") }

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
