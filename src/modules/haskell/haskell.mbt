///|
pub struct HaskellModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn HaskellModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "haskell",
  ),
) -> HaskellModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="λ "),
    detect_files: ["stack.yaml", "cabal.project"],
    detect_extensions: [".hs", ".cabal", ".hs-boot"],
  }
}

///|
pub fn HaskellModule::from_config(config : @config.Config) -> HaskellModule {
  HaskellModule::new(config=config.get_module("haskell"))
}

///|
pub impl @ms.PromptModule for HaskellModule with name(_self) -> String {
  "haskell"
}

///|
pub impl @ms.PromptModule for HaskellModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for HaskellModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Haskell project detected")
  }

  let version = @exec.exec_cmd("ghc", ["--numeric-version"])
  guard not(version.is_empty()) else { return Skipped("ghc not found") }

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
