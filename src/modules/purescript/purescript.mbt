///|
pub struct PureScriptModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn PureScriptModule::default() -> PureScriptModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold white",
    symbol: "<=> ",
    detect_files: ["spago.dhall", "spago.yaml", "spago.lock"],
    detect_extensions: [".purs"],
  }
}

///|
pub fn PureScriptModule::from_toml_table(
  table : @config.ModuleTable,
) -> PureScriptModule {
  let d = PureScriptModule::default()
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
pub fn PureScriptModule::from_config(
  config : @config.Config,
) -> PureScriptModule {
  match config.get_raw_module("purescript") {
    Some(table) => PureScriptModule::from_toml_table(table)
    None => PureScriptModule::default()
  }
}

///|
pub impl @ms.PromptModule for PureScriptModule with name(_self) -> String {
  "purescript"
}

///|
pub impl @ms.PromptModule for PureScriptModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for PureScriptModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no PureScript project detected")
  }

  let version = @exec.exec_cmd("purs", ["--version"])
  guard not(version.is_empty()) else { return Skipped("purs not found") }

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
