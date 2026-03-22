///|
pub struct BufModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn BufModule::default() -> BufModule {
  {
    disabled: false,
    async_render: false,
    format: "with [$symbol($version )]($style)",
    style: "bold blue",
    symbol: "🐃 ",
    detect_files: ["buf.yaml", "buf.gen.yaml", "buf.work.yaml"],
    detect_extensions: [],
  }
}

///|
pub fn BufModule::from_table(table : @config.ModuleTable) -> BufModule {
  let d = BufModule::default()
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
pub fn BufModule::from_config(config : @config.Config) -> BufModule {
  match config.get_raw_module("buf") {
    Some(table) => BufModule::from_table(table)
    None => BufModule::default()
  }
}

///|
pub impl @ms.PromptModule for BufModule with name(_self) -> String {
  "buf"
}

///|
pub impl @ms.PromptModule for BufModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for BufModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Buf project detected")
  }

  let version = @exec.exec_cmd("buf", ["--version"])
  guard not(version.is_empty()) else { return Skipped("buf not found") }

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
pub fn BufModule::schema() -> @config.ModuleSchema {
  let d = BufModule::default()
  {
    name: "buf",
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
