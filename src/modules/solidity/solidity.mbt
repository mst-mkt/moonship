///|
pub struct SolidityModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn SolidityModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "solidity",
  ),
) -> SolidityModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="S "),
    detect_files: [],
    detect_extensions: [".sol"],
  }
}

///|
pub fn SolidityModule::from_config(config : @config.Config) -> SolidityModule {
  SolidityModule::new(config=config.get_module("solidity"))
}

///|
pub impl @ms.PromptModule for SolidityModule with name(_self) -> String {
  "solidity"
}

///|
pub impl @ms.PromptModule for SolidityModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Solidity project detected")
  }

  let output = @exec.exec_cmd("solc", ["--version"])
  guard not(output.is_empty()) else { return Skipped("solc not found") }

  let version = @exec.find_semver(output)
  guard not(version.is_empty()) else {
    return Skipped("could not parse solc version")
  }

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
