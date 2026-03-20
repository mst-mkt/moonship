///|
pub struct JavaModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn JavaModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module("java"),
) -> JavaModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="☕ "),
    detect_files: [
      "pom.xml", "build.gradle.kts", "build.sbt", ".java-version", "deps.edn", "project.clj",
      "build.boot", ".sdkmanrc",
    ],
    detect_extensions: [".java", ".class", ".jar", ".gradle", ".clj", ".cljc"],
  }
}

///|
pub fn JavaModule::from_config(config : @config.Config) -> JavaModule {
  JavaModule::new(config=config.get_module("java"))
}

///|
pub impl @ms.PromptModule for JavaModule with name(_self) -> String {
  "java"
}

///|
pub impl @ms.PromptModule for JavaModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Java project detected")
  }

  let output = @exec.exec_cmd("java", ["-Xinternalversion"])
  guard not(output.is_empty()) else { return Skipped("java not found") }

  let display = parse_java_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse java version")
  }

  let vars : Map[String, String] = {
    "version": display,
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
fn parse_java_version(output : String) -> String {
  let jre_marker = "JRE ("
  match output.find(jre_marker) {
    Some(idx) => extract_version(output, idx + jre_marker.length())
    None => {
      let openj9_marker = "OpenJ9 "
      match output.find(openj9_marker) {
        Some(idx) => extract_version(output, idx + openj9_marker.length())
        None => ""
      }
    }
  }
}

///|
fn extract_version(s : String, start : Int) -> String {
  let buf = StringBuilder::new()
  let len = s.length()

  for i = start; i < len; i = i + 1 {
    let c = s[i].unsafe_to_char()
    if (c >= '0' && c <= '9') || c == '.' {
      buf.write_char(c)
    } else {
      break
    }
  }

  buf.to_string()
}
