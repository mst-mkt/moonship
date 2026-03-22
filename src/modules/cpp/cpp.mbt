///|
pub struct CppModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
  commands : Array[(String, String)]
}

///|
pub fn CppModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("cpp"),
) -> CppModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="C++ "),
    detect_files: [],
    detect_extensions: [
      ".cpp", ".cc", ".cxx", ".c++", ".hpp", ".hh", ".hxx", ".h++", ".tcc",
    ],
    commands: [
      ("c++", "--version"),
      ("g++", "--version"),
      ("clang++", "--version"),
    ],
  }
}

///|
pub fn CppModule::from_config(config : @config.Config) -> CppModule {
  CppModule::new(config=config.get_module("cpp"))
}

///|
pub impl @ms.PromptModule for CppModule with name(_self) -> String {
  "cpp"
}

///|
pub impl @ms.PromptModule for CppModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for CppModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no C++ project detected")
  }

  let output = @exec.try_commands(self.commands)
  guard not(output.is_empty()) else { return Skipped("c++ not found") }

  let version = @exec.find_semver(output)
  guard not(version.is_empty()) else {
    return Skipped("could not parse c++ version")
  }

  let vars : Map[String, String] = {
    "version": @exec.add_v_prefix(version),
    "symbol": self.symbol,
    "style": self.style,
  }

  let name = @exec.detect_compiler_name(output, [
    ("clang++", "clang"),
    ("g++", "Free Software Foundation"),
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
