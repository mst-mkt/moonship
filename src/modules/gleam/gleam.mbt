///|
pub struct GleamModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn GleamModule::default() -> GleamModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold #FFAFF3",
    symbol: "⭐ ",
    detect_files: ["gleam.toml"],
    detect_extensions: [".gleam"],
  }
}

///|
pub fn GleamModule::from_toml_table(table : @config.ModuleTable) -> GleamModule {
  let d = GleamModule::default()
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
pub fn GleamModule::from_config(config : @config.Config) -> GleamModule {
  match config.get_raw_module("gleam") {
    Some(table) => GleamModule::from_toml_table(table)
    None => GleamModule::default()
  }
}

///|
pub impl @ms.PromptModule for GleamModule with name(_self) -> String {
  "gleam"
}

///|
pub impl @ms.PromptModule for GleamModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for GleamModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Gleam project detected")
  }

  let output = @exec.exec_cmd("gleam", ["--version"])
  guard not(output.is_empty()) else { return Skipped("gleam not found") }

  let display = parse_gleam_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse gleam version")
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
fn parse_gleam_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() == 0 {
    return ""
  }

  parts[parts.length() - 1].to_string()
}

///|
pub fn GleamModule::schema() -> @config.ModuleSchema {
  let d = GleamModule::default()
  {
    name: "gleam",
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
