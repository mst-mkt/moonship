///|
pub struct PhpModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn PhpModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("php"),
) -> PhpModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🐘 "),
    detect_files: ["composer.json", ".php-version"],
    detect_extensions: [".php"],
  }
}

///|
pub fn PhpModule::from_config(config : @config.Config) -> PhpModule {
  PhpModule::new(config=config.get_module("php"))
}

///|
pub impl @ms.PromptModule for PhpModule with name(_self) -> String {
  "php"
}

///|
pub impl @ms.PromptModule for PhpModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no PHP project detected")
  }

  let output = @exec.exec_cmd("php", [
    "-nr", "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION.'.'.PHP_RELEASE_VERSION;",
  ])
  guard not(output.is_empty()) else { return Skipped("php not found") }

  let vars : Map[String, String] = {
    "version": @exec.add_v_prefix(output),
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
