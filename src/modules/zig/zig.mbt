///|
pub struct ZigModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn ZigModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("zig"),
) -> ZigModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="↯ "),
    detect_files: [],
    detect_extensions: [".zig"],
  }
}

///|
pub fn ZigModule::from_config(config : @config.Config) -> ZigModule {
  ZigModule::new(config=config.get_module("zig"))
}

///|
pub impl @ms.PromptModule for ZigModule with name(_self) -> String {
  "zig"
}

///|
pub impl @ms.PromptModule for ZigModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for ZigModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Zig project detected")
  }

  let version = @exec.exec_cmd("zig", ["version"])
  guard not(version.is_empty()) else { return Skipped("zig not found") }

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
