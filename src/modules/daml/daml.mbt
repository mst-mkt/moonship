///|
pub struct DamlModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn DamlModule::default() -> DamlModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold cyan",
    symbol: "Λ ",
    detect_files: ["daml.yaml"],
    detect_extensions: [],
  }
}

///|
pub fn DamlModule::from_toml_table(table : @config.ModuleTable) -> DamlModule {
  let d = DamlModule::default()
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
pub fn DamlModule::from_config(config : @config.Config) -> DamlModule {
  match config.get_raw_module("daml") {
    Some(table) => DamlModule::from_toml_table(table)
    None => DamlModule::default()
  }
}

///|
pub impl @ms.PromptModule for DamlModule with name(_self) -> String {
  "daml"
}

///|
pub impl @ms.PromptModule for DamlModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for DamlModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no DAML project detected")
  }

  let version = @sys.get_env_var("DAML_SDK_VERSION").unwrap_or("")

  let version = if version.is_empty() {
    let yaml_path = ctx.cwd + "/daml.yaml"
    let content = @fs.read_file_to_string(yaml_path) catch { _ => "" }
    parse_sdk_version(content)
  } else {
    version
  }

  guard not(version.is_empty()) else {
    return Skipped("could not determine DAML SDK version")
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

///|
fn parse_sdk_version(content : String) -> String {
  let lines = content.split("\n").collect()

  for line in lines {
    let s = line.to_string()

    if s.has_prefix("sdk-version:") {
      let parts = s.split(":").collect()
      if parts.length() >= 2 {
        return parts[1]
          .to_string()
          .trim_start(chars=" ")
          .trim_end(chars=" ")
          .to_string()
      }
    }
  }

  ""
}
