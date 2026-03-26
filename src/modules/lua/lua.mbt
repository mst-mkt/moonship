///|
pub struct LuaModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  version_format : String
  lua_binary : String
  detect_files : Array[String]
  detect_folders : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn LuaModule::default() -> LuaModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold blue",
    symbol: "🌙 ",
    version_format: "v${raw}",
    lua_binary: "lua",
    detect_files: [".lua-version"],
    detect_folders: ["lua"],
    detect_extensions: [".lua"],
  }
}

///|
pub fn LuaModule::from_table(table : @config.ModuleTable) -> LuaModule {
  let d = LuaModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    version_format: table
    .get_string("version_format")
    .unwrap_or(d.version_format),
    lua_binary: table.get_string("lua_binary").unwrap_or(d.lua_binary),
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
pub fn LuaModule::from_config(config : @config.Config) -> LuaModule {
  match config.get_raw_module("lua") {
    Some(table) => LuaModule::from_table(table)
    None => LuaModule::default()
  }
}

///|
pub impl @ms.PromptModule for LuaModule with name(_self) -> String {
  "lua"
}

///|
pub impl @ms.PromptModule for LuaModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for LuaModule with execute(
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
    return Skipped("no Lua project detected")
  }

  let output = @exec.exec_cmd(self.lua_binary, ["-v"])
  guard not(output.is_empty()) else { return Skipped("lua not found") }

  let display = parse_lua_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse lua version")
  }

  let vars : Map[String, String] = {
    "version": @exec.format_version(display, self.version_format),
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
fn parse_lua_version(output : String) -> String {
  let parts = output.split(" ").map(fn(s) { s.to_string() }).collect()
  if parts.length() >= 2 {
    parts[1]
  } else {
    ""
  }
}

///|
pub fn LuaModule::schema() -> @config.ModuleSchema {
  let d = LuaModule::default()
  {
    name: "lua",
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
        name: "lua_binary",
        field_type: @config.FString,
        default_value: d.lua_binary,
      },
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
