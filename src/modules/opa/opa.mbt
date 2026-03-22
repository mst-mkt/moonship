///|
pub struct OpaModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn OpaModule::default() -> OpaModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold blue",
    symbol: "🪖 ",
    detect_files: [],
    detect_extensions: [".rego"],
  }
}

///|
pub fn OpaModule::from_toml_table(table : @config.ModuleTable) -> OpaModule {
  let d = OpaModule::default()
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
pub fn OpaModule::from_config(config : @config.Config) -> OpaModule {
  match config.get_raw_module("opa") {
    Some(table) => OpaModule::from_toml_table(table)
    None => OpaModule::default()
  }
}

///|
pub impl @ms.PromptModule for OpaModule with name(_self) -> String {
  "opa"
}

///|
pub impl @ms.PromptModule for OpaModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for OpaModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no OPA project detected")
  }

  let output = @exec.exec_cmd("opa", ["version"])
  guard not(output.is_empty()) else { return Skipped("opa not found") }

  let display = parse_opa_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse opa version")
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
fn parse_opa_version(output : String) -> String {
  let lines = output.split("\n").collect()
  if lines.length() == 0 {
    return ""
  }

  let first_line = lines[0].to_string()
  let parts = first_line.split(" ").collect()
  if parts.length() == 0 {
    return ""
  }

  parts[parts.length() - 1].to_string()
}

///|
pub fn OpaModule::schema() -> @config.ModuleSchema {
  let d = OpaModule::default()
  {
    name: "opa",
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
