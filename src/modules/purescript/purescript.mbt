///|
pub struct PureScriptModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn PureScriptModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "purescript",
  ),
) -> PureScriptModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="<=> "),
    detect_files: ["spago.dhall", "spago.yaml", "spago.lock"],
    detect_extensions: [".purs"],
  }
}

///|
pub fn PureScriptModule::from_config(
  config : @config.Config,
) -> PureScriptModule {
  PureScriptModule::new(config=config.get_module("purescript"))
}

///|
pub impl @ms.PromptModule for PureScriptModule with name(_self) -> String {
  "purescript"
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
