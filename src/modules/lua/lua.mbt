///|
pub struct LuaModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
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
    lua_binary: "lua",
    detect_files: [".lua-version"],
    detect_folders: ["lua"],
    detect_extensions: [".lua"],
  }
}

///|
pub fn LuaModule::from_toml_table(table : @config.ModuleTable) -> LuaModule {
  let d = LuaModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
    lua_binary: @config.get_toml_string(table, "lua_binary").unwrap_or(
      d.lua_binary,
    ),
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
pub fn LuaModule::from_config(config : @config.Config) -> LuaModule {
  match config.get_raw_module("lua") {
    Some(table) => LuaModule::from_toml_table(table)
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
fn parse_lua_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() >= 2 {
    parts[1].to_string()
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
