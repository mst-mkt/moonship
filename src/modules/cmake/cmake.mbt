///|
pub struct CMakeModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn CMakeModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("cmake"),
) -> CMakeModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="△ "),
    detect_files: ["CMakeLists.txt", "CMakeCache.txt"],
    detect_extensions: [],
  }
}

///|
pub fn CMakeModule::from_config(config : @config.Config) -> CMakeModule {
  CMakeModule::new(config=config.get_module("cmake"))
}

///|
pub impl @ms.PromptModule for CMakeModule with name(_self) -> String {
  "cmake"
}

///|
pub impl @ms.PromptModule for CMakeModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for CMakeModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no CMake project detected")
  }

  let output = @exec.exec_cmd("cmake", ["--version"])
  guard not(output.is_empty()) else { return Skipped("cmake not found") }

  let display = parse_cmake_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse cmake version")
  }

  let vars : Map[String, String] = {
    "version": @exec.add_v_prefix(display),
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

///|
fn parse_cmake_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() >= 3 {
    parts[2].to_string()
  } else {
    ""
  }
}
