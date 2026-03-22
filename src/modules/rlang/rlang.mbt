///|
pub struct RlangModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_folders : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn RlangModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("rlang"),
) -> RlangModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="📐 "),
    detect_files: ["DESCRIPTION"],
    detect_folders: [".Rproj.user"],
    detect_extensions: [".R", ".Rd", ".Rmd", ".Rproj", ".Rsx"],
  }
}

///|
pub fn RlangModule::from_config(config : @config.Config) -> RlangModule {
  RlangModule::new(config=config.get_module("rlang"))
}

///|
pub impl @ms.PromptModule for RlangModule with name(_self) -> String {
  "rlang"
}

///|
pub impl @ms.PromptModule for RlangModule with execute(
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
    return Skipped("no R project detected")
  }

  let output = @exec.exec_cmd("R", ["--version"])
  guard not(output.is_empty()) else { return Skipped("R not found") }

  let parts = output.split(" ").collect()
  guard parts.length() >= 3 else { return Skipped("could not parse R version") }

  let version = parts[2].to_string()
  guard not(version.is_empty()) else {
    return Skipped("could not parse R version")
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
