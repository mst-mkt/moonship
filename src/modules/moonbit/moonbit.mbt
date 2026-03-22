///|
pub struct MoonbitModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn MoonbitModule::default() -> MoonbitModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "bold 125",
    symbol: "🐰 ",
    detect_files: ["moon.mod.json", "moon.pkg.json"],
    detect_extensions: [".mbt"],
  }
}

///|
pub fn MoonbitModule::from_table(table : @config.ModuleTable) -> MoonbitModule {
  let d = MoonbitModule::default()
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
pub fn MoonbitModule::from_config(config : @config.Config) -> MoonbitModule {
  match config.get_raw_module("moonbit") {
    Some(table) => MoonbitModule::from_table(table)
    None => MoonbitModule::default()
  }
}

///|
pub impl @ms.PromptModule for MoonbitModule with name(_self) -> String {
  "moonbit"
}

///|
pub impl @ms.PromptModule for MoonbitModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for MoonbitModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no MoonBit project detected")
  }

  let output = @exec.exec_cmd("moon", ["version"])
  guard not(output.is_empty()) else { return Skipped("moon not found") }

  let display = parse_moon_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse moon version")
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
fn parse_moon_version(output : String) -> String {
  let parts = output.split(" ").map(fn(s) { s.to_string() }).collect()
  if parts.length() >= 2 {
    parts[1]
  } else {
    ""
  }
}

///|
pub fn MoonbitModule::schema() -> @config.ModuleSchema {
  let d = MoonbitModule::default()
  {
    name: "moonbit",
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
