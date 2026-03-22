///|
pub struct GradleModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_folders : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn GradleModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "gradle",
  ),
) -> GradleModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🅶 "),
    detect_files: [],
    detect_folders: ["gradle"],
    detect_extensions: [".gradle", ".gradle.kts"],
  }
}

///|
pub fn GradleModule::from_config(config : @config.Config) -> GradleModule {
  GradleModule::new(config=config.get_module("gradle"))
}

///|
pub impl @ms.PromptModule for GradleModule with name(_self) -> String {
  "gradle"
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
  let mut version = parse_gradle_wrapper_version(content)

  if version.is_empty() {
    let output = @exec.exec_cmd("gradle", ["--version"])
    version = parse_gradle_cli_version(output)
  }

  guard not(version.is_empty()) else {
    return Skipped("could not determine gradle version")
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
fn parse_gradle_wrapper_version(content : String) -> String {
  let lines = content.split("\n").collect()

  for line in lines {
    let s = line.to_string()
    if s.has_prefix("distributionUrl") {
      return extract_gradle_version(s)
    }
  }

  ""
}

///|
fn parse_gradle_cli_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() >= 2 && parts[0].to_string() == "Gradle" {
    parts[1].to_string()
  } else {
    ""
  }
}

///|
fn extract_gradle_version(url_line : String) -> String {
  let parts = url_line.split("/").collect()

  for part in parts {
    let s = part.to_string()
    if s.has_prefix("gradle-") {
      let after = s["gradle-".length():].to_string()
      match after.find("-") {
        Some(idx) => return after[:idx].to_string()
        None => return after
      }
    }
  }

  ""
}
