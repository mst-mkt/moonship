///|
pub struct ElixirModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  version_format : String
  detect_files : Array[String]
  detect_extensions : Array[String]
  detect_folders : Array[String]
}

///|
pub fn ElixirModule::default() -> ElixirModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version \\(OTP $otp_version\\) )]($style)",
    style: "bold purple",
    symbol: "💧 ",
    version_format: "v${raw}",
    detect_files: ["mix.exs"],
    detect_extensions: [],
    detect_folders: [],
  }
}

///|
pub fn ElixirModule::from_table(table : @config.ModuleTable) -> ElixirModule {
  let d = ElixirModule::default()
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
    detect_folders: table
    .get_string_array("detect_folders")
    .unwrap_or(d.detect_folders),
  }
}

///|
pub fn ElixirModule::from_config(config : @config.Config) -> ElixirModule {
  match config.get_raw_module("elixir") {
    Some(table) => ElixirModule::from_table(table)
    None => ElixirModule::default()
  }
}

///|
pub impl @ms.PromptModule for ElixirModule with name(_self) -> String {
  "elixir"
}

///|
pub impl @ms.PromptModule for ElixirModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for ElixirModule with execute(
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
    return Skipped("no Elixir project detected")
  }

  let output = @exec.exec_cmd_full("elixir", ["--version"])
  guard not(output.is_empty()) else { return Skipped("elixir not found") }

  let (elixir_version, otp_version) = parse_elixir_version(output)
  guard not(elixir_version.is_empty()) else {
    return Skipped("could not parse elixir version")
  }

  let vars : Map[String, String] = {
    "version": @exec.format_version(elixir_version, self.version_format),
    "symbol": self.symbol,
    "style": self.style,
  }

  if not(otp_version.is_empty()) {
    vars["otp_version"] = otp_version
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn parse_elixir_version(output : String) -> (String, String) {
  output
  .split("\n")
  .fold(init=("", ""), fn(acc, line) {
    let s = line.to_string()
    let (elixir, otp) = acc

    if s.has_prefix("Erlang/OTP") {
      let parts = s.split(" ").map(fn(p) { p.to_string() }).collect()
      (elixir, if parts.length() >= 2 { parts[1] } else { otp })
    } else if s.has_prefix("Elixir") {
      let parts = s.split(" ").map(fn(p) { p.to_string() }).collect()
      (if parts.length() >= 2 { parts[1] } else { elixir }, otp)
    } else {
      (elixir, otp)
    }
  })
}

///|
pub fn ElixirModule::schema() -> @config.ModuleSchema {
  let d = ElixirModule::default()
  {
    name: "elixir",
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
      {
        name: "detect_folders",
        field_type: @config.FStringArray,
        default_value: d.detect_folders.join(", "),
      },
      {
        name: "version_format",
        field_type: @config.FString,
        default_value: d.version_format,
      },
    ],
  }
}
