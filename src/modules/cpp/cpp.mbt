///|
pub struct CppModule {
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
pub fn CppModule::default() -> CppModule {
  {
    disabled: true,
    async_render: false,
    format: "via [$symbol($version(-$name) )]($style)",
    style: "149 bold",
    symbol: "C++ ",
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
pub fn CppModule::from_toml_table(table : @config.ModuleTable) -> CppModule {
  let d = CppModule::default()
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
pub fn CppModule::from_config(config : @config.Config) -> CppModule {
  match config.get_raw_module("cpp") {
    Some(table) => CppModule::from_toml_table(table)
    None => CppModule::default()
  }
}

///|
pub impl @ms.PromptModule for CppModule with name(_self) -> String {
  "cpp"
}

///|
pub impl @ms.PromptModule for CppModule with is_async(self) -> Bool {
  self.async_render
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

///|
pub fn CppModule::schema() -> @config.ModuleSchema {
  let d = CppModule::default()
  {
    name: "cpp",
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
