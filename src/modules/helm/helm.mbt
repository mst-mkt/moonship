///|
pub struct HelmModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  version_format : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn HelmModule::default() -> HelmModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold white",
    symbol: "⎈ ",
    version_format: "v${raw}",
    detect_files: ["helmfile.yaml", "Chart.yaml"],
    detect_extensions: [],
  }
}

///|
pub fn HelmModule::from_table(table : @config.ModuleTable) -> HelmModule {
  let d = HelmModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    version_format: table
    .get_string("version_format")
    .unwrap_or(d.version_format),
    detect_files: table
    .get_string_array("detect_files")
    .unwrap_or(d.detect_files),
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(d.detect_extensions),
  }
}

///|
pub fn HelmModule::from_config(config : @config.Config) -> HelmModule {
  match config.get_raw_module("helm") {
    Some(table) => HelmModule::from_table(table)
    None => HelmModule::default()
  }
}

///|
pub impl @ms.PromptModule for HelmModule with name(_self) -> String {
  "helm"
}

///|
pub impl @ms.PromptModule for HelmModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for HelmModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Helm project detected")
  }

  let output = @exec.exec_cmd("helm", ["version", "--short"])
  guard not(output.is_empty()) else { return Skipped("helm not found") }

  let display = parse_helm_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse helm version")
  }

  let vars : Map[String, String] = {
    "version": @exec.format_version(display, self.version_format),
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
fn parse_helm_version(output : String) -> String {
  let stripped = @exec.strip_v_prefix(output)
  let parts = stripped.split("+").collect()
  if parts.length() == 0 {
    return ""
  }

  parts[0].to_string()
}

///|
pub fn HelmModule::schema() -> @config.ModuleSchema {
  let d = HelmModule::default()
  {
    name: "helm",
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
