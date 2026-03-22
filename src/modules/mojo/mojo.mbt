///|
pub struct MojoModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn MojoModule::default() -> MojoModule {
  {
    disabled: false,
    async_render: false,
    format: "with [$symbol($version )]($style)",
    style: "bold 208",
    symbol: "🔥 ",
    detect_files: [],
    detect_extensions: [".mojo", ".🔥"],
  }
}

///|
pub fn MojoModule::from_table(table : @config.ModuleTable) -> MojoModule {
  let d = MojoModule::default()
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
pub fn MojoModule::from_config(config : @config.Config) -> MojoModule {
  match config.get_raw_module("mojo") {
    Some(table) => MojoModule::from_table(table)
    None => MojoModule::default()
  }
}

///|
pub impl @ms.PromptModule for MojoModule with name(_self) -> String {
  "mojo"
}

///|
pub impl @ms.PromptModule for MojoModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for MojoModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Mojo project detected")
  }

  let output = @exec.exec_cmd("mojo", ["--version"])
  guard not(output.is_empty()) else { return Skipped("mojo not found") }

  let display = parse_mojo_version(output)
  guard not(display.is_empty()) else {
    return Skipped("could not parse mojo version")
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
fn parse_mojo_version(output : String) -> String {
  output.split(" ").fold(init="", fn(_prev, s) { s.to_string() })
}

///|
pub fn MojoModule::schema() -> @config.ModuleSchema {
  let d = MojoModule::default()
  {
    name: "mojo",
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
