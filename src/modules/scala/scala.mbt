///|
pub struct ScalaModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
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
    detect_files: [".scalaenv", ".sbtenv", "build.sbt"],
    detect_folders: [".metals"],
    detect_extensions: [".sbt", ".scala"],
  }
}

///|
pub fn ScalaModule::from_toml_table(table : @config.ModuleTable) -> ScalaModule {
  let d = ScalaModule::default()
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
    detect_folders: @config.get_toml_string_array(table, "detect_folders").unwrap_or(
      d.detect_folders,
    ),
    detect_extensions: @config.get_toml_string_array(table, "detect_extensions").unwrap_or(
      d.detect_extensions,
    ),
  }
}

///|
pub fn ScalaModule::from_config(config : @config.Config) -> ScalaModule {
  match config.get_raw_module("scala") {
    Some(table) => ScalaModule::from_toml_table(table)
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
      "version": @exec.add_v_prefix(version),
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
fn parse_scalac_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() >= 4 {
    parts[3].to_string()
  } else {
    ""
  }
}
