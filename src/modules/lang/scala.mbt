///|
pub struct ScalaModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  version_format : String
  detect_files : Array[String]
  detect_folders : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn ScalaModule::default() -> ScalaModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "red bold",
    symbol: "🆂 ",
    version_format: "v${raw}",
    detect_files: [".scalaenv", ".sbtenv", "build.sbt"],
    detect_folders: [".metals"],
    detect_extensions: [".sbt", ".scala"],
  }
}

///|
pub fn ScalaModule::from_table(table : @config.ModuleTable) -> ScalaModule {
  let d = ScalaModule::default()
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
    detect_folders: table
    .get_string_array("detect_folders")
    .unwrap_or(d.detect_folders),
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(d.detect_extensions),
  }
}

///|
pub fn ScalaModule::from_config(config : @config.Config) -> ScalaModule {
  match config.get_raw_module("scala") {
    Some(table) => ScalaModule::from_table(table)
    None => ScalaModule::default()
  }
}

///|
pub impl @ms.PromptModule for ScalaModule with name(_self) -> String {
  "scala"
}

///|
pub impl @ms.PromptModule for ScalaModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for ScalaModule with execute(
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
    return Skipped("no Scala project detected")
  }

  let version = @exec.exec_cmd("scala-cli", ["version", "--scala"])
  if not(version.is_empty()) {
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
    return Output(@ms.ModuleOutput::new(segments))
  }

  let output = @exec.exec_cmd("scalac", ["-version"])
  guard not(output.is_empty()) else { return Skipped("scala not found") }

  let display = parse_scalac_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse scala version")
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
fn parse_scalac_version(output : String) -> String {
  let parts = output.split(" ").map(fn(s) { s.to_string() }).collect()
  if parts.length() >= 4 {
    parts[3]
  } else {
    ""
  }
}

///|
pub fn ScalaModule::schema() -> @config.ModuleSchema {
  let d = ScalaModule::default()
  {
    name: "scala",
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
    ],
  }
}
