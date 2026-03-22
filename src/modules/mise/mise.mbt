///|
pub struct MiseModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  healthy_symbol : String
  unhealthy_symbol : String
  detect_files : Array[String]
  detect_folders : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn MiseModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("mise"),
) -> MiseModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="mise "),
    healthy_symbol: config.get_prop("healthy_symbol", default="healthy"),
    unhealthy_symbol: config.get_prop("unhealthy_symbol", default="unhealthy"),
    detect_files: [
      "mise.toml", "mise.local.toml", ".mise.toml", ".mise.local.toml",
    ],
    detect_folders: [".mise"],
    detect_extensions: [],
  }
}

///|
pub fn MiseModule::from_config(config : @config.Config) -> MiseModule {
  MiseModule::new(config=config.get_module("mise"))
}

///|
pub impl @ms.PromptModule for MiseModule with name(_self) -> String {
  "mise"
}

///|
pub impl @ms.PromptModule for MiseModule with execute(
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
    return Skipped("no mise project detected")
  }

  let doctor_output = @exec.exec_cmd("mise", ["doctor"])
  let health = if not(doctor_output.is_empty()) {
    self.healthy_symbol
  } else {
    self.unhealthy_symbol
  }

  let vars : Map[String, String] = {
    "symbol": self.symbol,
    "health": health,
    "style": self.style,
  }
  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}
