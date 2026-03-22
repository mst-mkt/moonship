///|
pub struct ElmModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_folders : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn ElmModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("elm"),
) -> ElmModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🌳 "),
    detect_files: ["elm.json", "elm-package.json", ".elm-version"],
    detect_folders: ["elm-stuff"],
    detect_extensions: [".elm"],
  }
}

///|
pub fn ElmModule::from_config(config : @config.Config) -> ElmModule {
  ElmModule::new(config=config.get_module("elm"))
}

///|
pub impl @ms.PromptModule for ElmModule with name(_self) -> String {
  "elm"
}

///|
pub impl @ms.PromptModule for ElmModule with execute(
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
    return Skipped("no Elm project detected")
  }

  let version = @exec.exec_cmd("elm", ["--version"])
  guard not(version.is_empty()) else { return Skipped("elm not found") }

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
