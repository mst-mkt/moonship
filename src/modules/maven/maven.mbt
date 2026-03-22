///|
pub struct MavenModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_folders : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn MavenModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("maven"),
) -> MavenModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="🅼 "),
    detect_files: ["pom.xml"],
    detect_folders: [".mvn"],
    detect_extensions: [],
  }
}

///|
pub fn MavenModule::from_config(config : @config.Config) -> MavenModule {
  MavenModule::new(config=config.get_module("maven"))
}

///|
pub impl @ms.PromptModule for MavenModule with name(_self) -> String {
  "maven"
}

///|
pub impl @ms.PromptModule for MavenModule with is_async(_self) -> Bool {
  false
}

///|
pub impl @ms.PromptModule for MavenModule with execute(
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
    return Skipped("no Maven project detected")
  }

  let props_path = ctx.cwd + "/.mvn/wrapper/maven-wrapper.properties"
  let content = @fs.read_file_to_string(props_path) catch { _ => "" }
  let mut version = parse_maven_wrapper_version(content)

  if version.is_empty() {
    let output = @exec.exec_cmd("mvn", ["--version"])
    version = parse_mvn_cli_version(output)
  }

  guard not(version.is_empty()) else {
    return Skipped("could not determine maven version")
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
fn parse_maven_wrapper_version(content : String) -> String {
  let lines = content.split("\n").collect()

  for line in lines {
    let s = line.to_string()
    if s.has_prefix("distributionUrl") {
      return extract_maven_version(s)
    }
  }

  ""
}

///|
fn parse_mvn_cli_version(output : String) -> String {
  let parts = output.split(" ").collect()
  if parts.length() >= 3 &&
    parts[0].to_string() == "Apache" &&
    parts[1].to_string() == "Maven" {
    parts[2].to_string()
  } else {
    ""
  }
}

///|
fn extract_maven_version(url_line : String) -> String {
  let parts = url_line.split("/").collect()

  for part in parts {
    let s = part.to_string()
    if s.has_prefix("apache-maven-") {
      let after = s["apache-maven-".length():].to_string()
      match after.find("-") {
        Some(idx) => return after[:idx].to_string()
        None => return after
      }
    }
  }

  ""
}
