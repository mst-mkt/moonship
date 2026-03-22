///|
pub struct HaxeModule {
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
pub fn HaxeModule::default() -> HaxeModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold fg:202",
    symbol: "⌘ ",
    detect_files: ["haxelib.json", "hxformat.json", ".haxerc"],
    detect_folders: [".haxelib", "haxe_libraries"],
    detect_extensions: [".hx", ".hxml"],
  }
}

///|
pub fn HaxeModule::from_toml_table(table : @config.ModuleTable) -> HaxeModule {
  let d = HaxeModule::default()
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
pub fn HaxeModule::from_config(config : @config.Config) -> HaxeModule {
  match config.get_raw_module("haxe") {
    Some(table) => HaxeModule::from_toml_table(table)
    None => HaxeModule::default()
  }
}

///|
pub impl @ms.PromptModule for HaxeModule with name(_self) -> String {
  "haxe"
}

///|
pub impl @ms.PromptModule for HaxeModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for HaxeModule with execute(
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
    return Skipped("no Haxe project detected")
  }

  let version = @exec.exec_cmd("haxe", ["--version"])
  guard not(version.is_empty()) else { return Skipped("haxe not found") }

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
