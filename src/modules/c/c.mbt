///|
pub struct CModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
  commands : Array[(String, String)]
}

///|
pub fn CModule::default() -> CModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version(-$name) )]($style)",
    style: "149 bold",
    symbol: "C ",
    detect_files: [],
    detect_extensions: [".c", ".h"],
    commands: [
      ("cc", "--version"),
      ("gcc", "--version"),
      ("clang", "--version"),
    ],
  }
}

///|
pub fn CModule::from_toml_table(table : @config.ModuleTable) -> CModule {
  let d = CModule::default()
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
    commands: d.commands,
  }
}

///|
pub fn CModule::from_config(config : @config.Config) -> CModule {
  match config.get_raw_module("c") {
    Some(table) => CModule::from_toml_table(table)
    None => CModule::default()
  }
}

///|
pub impl @ms.PromptModule for CModule with name(_self) -> String {
  "c"
}

///|
pub impl @ms.PromptModule for CModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for CModule with execute(self, ctx : @context.Context) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no C project detected")
  }

  let output = @exec.try_commands(self.commands)
  guard not(output.is_empty()) else { return Skipped("cc not found") }

  let version = @exec.find_semver(output)
  guard not(version.is_empty()) else {
    return Skipped("could not parse cc version")
  }

  let vars : Map[String, String] = {
    "version": @exec.add_v_prefix(version),
    "symbol": self.symbol,
    "style": self.style,
  }

  let name = @exec.detect_compiler_name(output, [
    ("clang", "clang"),
    ("gcc", "Free Software Foundation"),
  ])
  if not(name.is_empty()) {
    vars["name"] = name
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}
