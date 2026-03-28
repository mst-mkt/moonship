///|
pub struct GradleModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  recursive : Bool
  version_format : String
  detect_files : Array[String]
  detect_folders : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn GradleModule::default() -> GradleModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold bright-cyan",
    symbol: "🅶 ",
    recursive: false,
    version_format: "v${raw}",
    detect_files: [],
    detect_folders: ["gradle"],
    detect_extensions: [".gradle", ".gradle.kts"],
  }
}

///|
pub fn GradleModule::from_table(table : @config.ModuleTable) -> GradleModule {
  let d = GradleModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    recursive: table.get_bool("recursive").unwrap_or(d.recursive),
    version_format: table
    .get_string("version_format")
    .unwrap_or(d.version_format),
    detect_files: table
    .get_string_array("detect_files")
    .unwrap_or(d.detect_files),
    detect_folders: table
    .get_string_array("detect_folders")
    .unwrap_or(d.detect_folders),
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(d.detect_extensions),
  }
}

///|
pub fn GradleModule::from_config(config : @config.Config) -> GradleModule {
  match config.get_raw_module("gradle") {
    Some(table) => GradleModule::from_table(table)
    None => GradleModule::default()
  }
}

///|
pub impl @ms.PromptModule for GradleModule with name(_self) -> String {
  "gradle"
}

///|
pub impl @ms.PromptModule for GradleModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for GradleModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(
    ctx.cwd,
    self.detect_files,
    self.detect_extensions,
    folders=self.detect_folders,
  ) else {
    return Skipped("no Gradle project detected")
  }

  let props_path = ctx.cwd + "/gradle/wrapper/gradle-wrapper.properties"
  let content = @fs.read_file_to_string(props_path) catch { _ => "" }
  let wrapper_version = parse_gradle_wrapper_version(content)
  let version = if wrapper_version.is_empty() {
    let output = @exec.exec_cmd("gradle", ["--version"])
    parse_gradle_cli_version(output)
  } else {
    wrapper_version
  }

  guard not(version.is_empty()) else {
    return Skipped("could not determine gradle version")
  }

  let vars : Map[String, String] = {
    "version": @exec.format_version(version, self.version_format),
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
fn parse_gradle_wrapper_version(content : String) -> String {
  content
  .split("\n")
  .map(fn(s) { s.to_string() })
  .find_first(fn(s) { s.has_prefix("distributionUrl") })
  .map(fn(s) { extract_gradle_version(s) })
  .unwrap_or("")
}

///|
fn parse_gradle_cli_version(output : String) -> String {
  match @exec.split_to_strings(output, " ") {
    ["Gradle", version, ..] => version
    _ => ""
  }
}

///|
fn extract_gradle_version(url_line : String) -> String {
  url_line
  .split("/")
  .map(fn(s) { s.to_string() })
  .find_first(fn(s) { s.has_prefix("gradle-") })
  .map(fn(s) {
    let after = s["gradle-".length():].to_string()
    match after.find("-") {
      Some(idx) => after[:idx].to_string()
      None => after
    }
  })
  .unwrap_or("")
}

///|
pub fn GradleModule::schema() -> @config.ModuleSchema {
  let d = GradleModule::default()
  {
    name: "gradle",
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
        name: "detect_folders",
        field_type: @config.FStringArray,
        default_value: d.detect_folders.join(", "),
      },
      {
        name: "detect_extensions",
        field_type: @config.FStringArray,
        default_value: d.detect_extensions.join(", "),
      },
      {
        name: "recursive",
        field_type: @config.FBool,
        default_value: d.recursive.to_string(),
      },
      {
        name: "version_format",
        field_type: @config.FString,
        default_value: d.version_format,
      },
    ],
  }
}
