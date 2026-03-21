///|
pub struct BunModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn BunModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("bun"),
) -> BunModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🥟 "),
    detect_files: ["bun.lock", "bun.lockb", "bunfig.toml"],
    detect_extensions: [],
  }
}

///|
pub fn BunModule::from_config(config : @config.Config) -> BunModule {
  BunModule::new(config=config.get_module("bun"))
}

///|
pub impl @ms.PromptModule for BunModule with name(_self) -> String {
  "bun"
}

///|
pub impl @ms.PromptModule for BunModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Bun project detected")
  }

  let version = @exec.exec_cmd("bun", ["--version"])
  guard not(version.is_empty()) else { return Skipped("bun not found") }

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
