///|
pub struct PerlModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn PerlModule::default() -> PerlModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "149 bold",
    symbol: "🐪 ",
    detect_files: [
      "Makefile.PL", "Build.PL", "cpanfile", "cpanfile.snapshot", "META.json", "META.yml",
      ".perl-version",
    ],
    detect_extensions: [".pl", ".pm", ".pod"],
  }
}

///|
pub fn PerlModule::from_toml_table(table : @config.ModuleTable) -> PerlModule {
  let d = PerlModule::default()
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
pub fn PerlModule::from_config(config : @config.Config) -> PerlModule {
  match config.get_raw_module("perl") {
    Some(table) => PerlModule::from_toml_table(table)
    None => PerlModule::default()
  }
}

///|
pub impl @ms.PromptModule for PerlModule with name(_self) -> String {
  "perl"
}

///|
pub impl @ms.PromptModule for PerlModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for PerlModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Perl project detected")
  }

  let output = @exec.exec_cmd("perl", ["-e", "printf q{%vd},$^V"])
  guard not(output.is_empty()) else { return Skipped("perl not found") }

  let vars : Map[String, String] = {
    "version": @exec.add_v_prefix(output),
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
