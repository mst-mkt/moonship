///|
pub struct VlangModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn VlangModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("vlang"),
) -> VlangModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="V "),
    detect_files: ["v.mod", "vpkg.json", ".vpkg-lock.json"],
    detect_extensions: [".v"],
  }
}

///|
pub fn VlangModule::from_config(config : @config.Config) -> VlangModule {
  VlangModule::new(config=config.get_module("vlang"))
}

///|
pub impl @ms.PromptModule for VlangModule with name(_self) -> String {
  "vlang"
}

///|
pub impl @ms.PromptModule for VlangModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no V project detected")
  }

  let output = @exec.exec_cmd("v", ["version"])
  guard not(output.is_empty()) else { return Skipped("v not found") }

  let parts = output.split(" ").collect()
  guard parts.length() >= 1 else { return Skipped("could not parse V version") }

  let version = parts[parts.length() - 1].to_string()
  guard not(version.is_empty()) else {
    return Skipped("could not parse V version")
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
