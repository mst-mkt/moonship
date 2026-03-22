///|
pub struct LuaModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  lua_binary : String
  detect_files : Array[String]
  detect_folders : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn LuaModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("lua"),
) -> LuaModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🌙 "),
    lua_binary: config.get_prop("lua_binary", default="lua"),
    detect_files: [".lua-version"],
    detect_folders: ["lua"],
    detect_extensions: [".lua"],
  }
}

///|
pub fn LuaModule::from_config(config : @config.Config) -> LuaModule {
  LuaModule::new(config=config.get_module("lua"))
}

///|
pub impl @ms.PromptModule for LuaModule with name(_self) -> String {
  "lua"
}

///|
pub impl @ms.PromptModule for LuaModule with is_async(_self) -> Bool {
  false
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
