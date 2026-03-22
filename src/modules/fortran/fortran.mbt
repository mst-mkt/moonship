///|
pub struct FortranModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
  commands : Array[(String, String)]
}

///|
pub fn FortranModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "fortran",
  ),
) -> FortranModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🅵  "),
    detect_files: ["fpm.toml"],
    detect_extensions: [
      ".f", ".F", ".for", ".FOR", ".ftn", ".FTN", ".f77", ".F77", ".f90", ".F90",
      ".f95", ".F95", ".f03", ".F03", ".f08", ".F08", ".f18", ".F18",
    ],
    commands: [
      ("gfortran", "--version"),
      ("flang", "--version"),
      ("flang-new", "--version"),
    ],
  }
}

///|
pub fn FortranModule::from_config(config : @config.Config) -> FortranModule {
  FortranModule::new(config=config.get_module("fortran"))
}

///|
pub impl @ms.PromptModule for FortranModule with name(_self) -> String {
  "fortran"
}

///|
pub impl @ms.PromptModule for FortranModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for FortranModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Fortran project detected")
  }

  let output = @exec.try_commands(self.commands)
  guard not(output.is_empty()) else {
    return Skipped("fortran compiler not found")
  }

  let version = @exec.find_semver(output)
  guard not(version.is_empty()) else {
    return Skipped("could not parse fortran version")
  }

  let vars : Map[String, String] = {
    "version": version,
    "symbol": self.symbol,
    "style": self.style,
  }

  let name = @exec.detect_compiler_name(output, [
    ("gfortran", "GNU Fortran"),
    ("flang", "flang"),
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
