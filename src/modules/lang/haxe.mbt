///|
pub struct HaxeModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  version_format : String
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
    version_format: "v${raw}",
    detect_files: ["haxelib.json", "hxformat.json", ".haxerc"],
    detect_folders: [".haxelib", "haxe_libraries"],
    detect_extensions: [".hx", ".hxml"],
  }
}

///|
pub fn HaxeModule::from_table(table : @config.ModuleTable) -> HaxeModule {
  let d = HaxeModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    version_format: table
    .get_string("version_format")
    .unwrap_or(d.version_format),
    detect_files: table
    .get_string_array("detect_files")
    .unwrap_or(d.detect_files),
    detect_folders: table
    .get_string_array("detect_folders")
    .unwrap_or(d.detect_folders),
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(d.detect_extensions),
  }
}

///|
pub fn HaxeModule::from_config(config : @config.Config) -> HaxeModule {
  match config.get_raw_module("haxe") {
    Some(table) => HaxeModule::from_table(table)
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
    "version": @exec.format_version(version, self.version_format),
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
pub fn HaxeModule::schema() -> @config.ModuleSchema {
  let d = HaxeModule::default()
  {
    name: "haxe",
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
        name: "detect_folders",
        field_type: @config.FStringArray,
        default_value: d.detect_folders.join(", "),
      },
      {
        name: "detect_extensions",
        field_type: @config.FStringArray,
        default_value: d.detect_extensions.join(", "),
      },
    ],
  }
}
