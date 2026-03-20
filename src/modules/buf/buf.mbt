///|
pub struct BufModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn BufModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("buf"),
) -> BufModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🐃 "),
    detect_files: ["buf.yaml", "buf.gen.yaml", "buf.work.yaml"],
    detect_extensions: [],
  }
}

///|
pub fn BufModule::from_config(config : @config.Config) -> BufModule {
  BufModule::new(config=config.get_module("buf"))
}

///|
pub impl @ms.PromptModule for BufModule with name(_self) -> String {
  "buf"
}

///|
pub impl @ms.PromptModule for BufModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Buf project detected")
  }

  let version = @exec.exec_cmd("buf", ["--version"])
  guard not(version.is_empty()) else { return Skipped("buf not found") }

  let vars : Map[String, String] = {
    "version": version,
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
