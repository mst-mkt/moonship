///|
pub struct QuartoModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn QuartoModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "quarto",
  ),
) -> QuartoModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="⨁ "),
    detect_files: ["_quarto.yml"],
    detect_extensions: [".qmd"],
  }
}

///|
pub fn QuartoModule::from_config(config : @config.Config) -> QuartoModule {
  QuartoModule::new(config=config.get_module("quarto"))
}

///|
pub impl @ms.PromptModule for QuartoModule with name(_self) -> String {
  "quarto"
}

///|
pub impl @ms.PromptModule for QuartoModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Quarto project detected")
  }

  let version = @exec.exec_cmd("quarto", ["--version"])
  guard not(version.is_empty()) else { return Skipped("quarto not found") }

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
