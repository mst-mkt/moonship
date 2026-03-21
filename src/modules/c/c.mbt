///|
pub struct CModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
  commands : Array[(String, String)]
}

///|
pub fn CModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("c"),
) -> CModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="C "),
    detect_files: [],
    detect_extensions: [".c", ".h"],
    commands: [
      ("cc", "--version"),
      ("gcc", "--version"),
      ("clang", "--version"),
    ],
  }
}

///|
pub fn CModule::from_config(config : @config.Config) -> CModule {
  CModule::new(config=config.get_module("c"))
}

///|
pub impl @ms.PromptModule for CModule with name(_self) -> String {
  "c"
}

///|
pub impl @ms.PromptModule for CModule with execute(self, ctx : @context.Context) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no C project detected")
  }

  let output = @exec.try_commands(self.commands)
  guard not(output.is_empty()) else { return Skipped("cc not found") }

  let version = @exec.find_semver(output)
  guard not(version.is_empty()) else {
    return Skipped("could not parse cc version")
  }

  let vars : Map[String, String] = {
    "version": @exec.add_v_prefix(version),
    "symbol": self.symbol,
    "style": self.style,
  }

  let name = @exec.detect_compiler_name(output, [
    ("clang", "clang"),
    ("gcc", "Free Software Foundation"),
  ])
  if not(name.is_empty()) {
    vars["name"] = name
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}
