///|
pub struct XmakeModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn XmakeModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("xmake"),
) -> XmakeModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="△ "),
    detect_files: ["xmake.lua"],
    detect_extensions: [],
  }
}

///|
pub fn XmakeModule::from_config(config : @config.Config) -> XmakeModule {
  XmakeModule::new(config=config.get_module("xmake"))
}

///|
pub impl @ms.PromptModule for XmakeModule with name(_self) -> String {
  "xmake"
}

///|
pub impl @ms.PromptModule for XmakeModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no xmake project detected")
  }

  let output = @exec.exec_cmd("xmake", ["--version"])
  guard not(output.is_empty()) else { return Skipped("xmake not found") }

  let version = @exec.find_semver(output)
  guard not(version.is_empty()) else {
    return Skipped("could not parse xmake version")
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
