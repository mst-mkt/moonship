///|
pub struct JuliaModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn JuliaModule::default() -> JuliaModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold purple",
    symbol: "ஃ ",
    detect_files: ["Project.toml", "Manifest.toml"],
    detect_extensions: [".jl"],
  }
}

///|
pub fn JuliaModule::from_toml_table(table : @config.ModuleTable) -> JuliaModule {
  let d = JuliaModule::default()
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
  }
}

///|
pub fn JuliaModule::from_config(config : @config.Config) -> JuliaModule {
  match config.get_raw_module("julia") {
    Some(table) => JuliaModule::from_toml_table(table)
    None => JuliaModule::default()
  }
}

///|
pub impl @ms.PromptModule for JuliaModule with name(_self) -> String {
  "julia"
}

///|
pub impl @ms.PromptModule for JuliaModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for JuliaModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Julia project detected")
  }

  let output = @exec.exec_cmd("julia", ["--version"])
  guard not(output.is_empty()) else { return Skipped("julia not found") }

  let display = parse_julia_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse julia version")
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
fn parse_julia_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() >= 3 {
    parts[2].to_string()
  } else {
    ""
  }
}

///|
pub fn JuliaModule::schema() -> @config.ModuleSchema {
  let d = JuliaModule::default()
  {
    name: "julia",
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
