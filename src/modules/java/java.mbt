///|
pub struct JavaModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn JavaModule::default() -> JavaModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "red dimmed",
    symbol: "☕ ",
    detect_files: [
      "pom.xml", "build.gradle.kts", "build.sbt", ".java-version", "deps.edn", "project.clj",
      "build.boot", ".sdkmanrc",
    ],
    detect_extensions: [".java", ".class", ".jar", ".gradle", ".clj", ".cljc"],
  }
}

///|
pub fn JavaModule::from_table(table : @config.ModuleTable) -> JavaModule {
  let d = JavaModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    detect_files: table
    .get_string_array("detect_files")
    .unwrap_or(d.detect_files),
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(d.detect_extensions),
  }
}

///|
pub fn JavaModule::from_config(config : @config.Config) -> JavaModule {
  match config.get_raw_module("java") {
    Some(table) => JavaModule::from_table(table)
    None => JavaModule::default()
  }
}

///|
pub impl @ms.PromptModule for JavaModule with name(_self) -> String {
  "java"
}

///|
pub impl @ms.PromptModule for JavaModule with is_async(self) -> Bool {
  self.async_render
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

  loop start {
    i if i >= len => break buf.to_string()
    i => {
      let c = s[i].unsafe_to_char()
      if (c >= '0' && c <= '9') || c == '.' {
        buf.write_char(c)
        continue i + 1
      } else {
        break buf.to_string()
      }
    }
  }
}

///|
pub fn JavaModule::schema() -> @config.ModuleSchema {
  let d = JavaModule::default()
  {
    name: "java",
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
