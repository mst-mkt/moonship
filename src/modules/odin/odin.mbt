///|
pub struct OdinModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn OdinModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("odin"),
) -> OdinModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="Ø "),
    detect_files: [],
    detect_extensions: [".odin"],
  }
}

///|
pub fn OdinModule::from_config(config : @config.Config) -> OdinModule {
  OdinModule::new(config=config.get_module("odin"))
}

///|
pub impl @ms.PromptModule for OdinModule with name(_self) -> String {
  "odin"
}

///|
pub impl @ms.PromptModule for OdinModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for OdinModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Odin project detected")
  }

  let output = @exec.exec_cmd("odin", ["version"])
  guard not(output.is_empty()) else { return Skipped("odin not found") }

  let display = parse_odin_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse odin version")
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
fn parse_odin_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() == 0 {
    return ""
  }

  parts[parts.length() - 1].to_string()
}
