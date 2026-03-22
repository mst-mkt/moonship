///|
pub struct FortranModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
  commands : Array[(String, String)]
}

///|
pub fn FortranModule::default() -> FortranModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version(-$name) )]($style)",
    style: "bold purple",
    symbol: "🅵  ",
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
pub fn FortranModule::from_toml_table(
  table : @config.ModuleTable,
) -> FortranModule {
  let d = FortranModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    symbol: @config.get_toml_string(table, "symbol").unwrap_or(d.symbol),
    detect_files: @config.get_toml_string_array(table, "detect_files").unwrap_or(
      d.detect_files,
    ),
    detect_extensions: @config.get_toml_string_array(table, "detect_extensions").unwrap_or(
      d.detect_extensions,
    ),
    commands: d.commands,
  }
}

///|
pub fn FortranModule::from_config(config : @config.Config) -> FortranModule {
  match config.get_raw_module("fortran") {
    Some(table) => FortranModule::from_toml_table(table)
    None => FortranModule::default()
  }
}

///|
pub impl @ms.PromptModule for FortranModule with name(_self) -> String {
  "fortran"
}

///|
pub impl @ms.PromptModule for FortranModule with is_async(self) -> Bool {
  self.async_render
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

///|
pub fn FortranModule::schema() -> @config.ModuleSchema {
  let d = FortranModule::default()
  {
    name: "fortran",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
      {
        name: "detect_files",
        field_type: @config.FStringArray,
        default_value: d.detect_files.join(", "),
      },
      {
        name: "detect_extensions",
        field_type: @config.FStringArray,
        default_value: d.detect_extensions.join(", "),
      },
    ],
  }
}
