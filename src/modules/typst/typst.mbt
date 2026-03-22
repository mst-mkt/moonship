///|
pub struct TypstModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn TypstModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("typst"),
) -> TypstModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="t "),
    detect_files: ["template.typ"],
    detect_extensions: [".typ"],
  }
}

///|
pub fn TypstModule::from_config(config : @config.Config) -> TypstModule {
  TypstModule::new(config=config.get_module("typst"))
}

///|
pub impl @ms.PromptModule for TypstModule with name(_self) -> String {
  "typst"
}

///|
pub impl @ms.PromptModule for TypstModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for TypstModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Typst project detected")
  }

  let output = @exec.exec_cmd("typst", ["--version"])
  guard not(output.is_empty()) else { return Skipped("typst not found") }

  let parts = output.split(" ").collect()
  guard parts.length() >= 2 else {
    return Skipped("could not parse typst version")
  }

  let version = parts[1].to_string()
  guard not(version.is_empty()) else {
    return Skipped("could not parse typst version")
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
