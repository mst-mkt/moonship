///|
pub struct SwiftModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn SwiftModule::default() -> SwiftModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold 202",
    symbol: "🐦 ",
    detect_files: ["Package.swift"],
    detect_extensions: [".swift"],
  }
}

///|
pub fn SwiftModule::from_table(table : @config.ModuleTable) -> SwiftModule {
  let d = SwiftModule::default()
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
pub fn SwiftModule::from_config(config : @config.Config) -> SwiftModule {
  match config.get_raw_module("swift") {
    Some(table) => SwiftModule::from_table(table)
    None => SwiftModule::default()
  }
}

///|
pub impl @ms.PromptModule for SwiftModule with name(_self) -> String {
  "swift"
}

///|
pub impl @ms.PromptModule for SwiftModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for SwiftModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Swift project detected")
  }

  let output = @exec.exec_cmd("swift", ["--version"])
  guard not(output.is_empty()) else { return Skipped("swift not found") }

  let display = parse_swift_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse swift version")
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
fn parse_swift_version(output : String) -> String {
  output
  .split(" ")
  .map(fn(s) { s.to_string() })
  .collect()
  .iter()
  .fold(init=("", false, false), fn(acc, s) {
    let (result, take_next, done) = acc
    if done {
      acc
    } else if take_next {
      (s, false, true)
    } else if s == "version" {
      (result, true, false)
    } else {
      acc
    }
  }).0
}

///|
pub fn SwiftModule::schema() -> @config.ModuleSchema {
  let d = SwiftModule::default()
  {
    name: "swift",
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
