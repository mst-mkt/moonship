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
pub fn BufModule::from_toml_table(table : @config.ModuleTable) -> BufModule {
  let d = BufModule::default()
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
    detect_extensions: @config.get_toml_string_array(table, "detect_extensions").unwrap_or(
      d.detect_extensions,
    ),
  }
}

///|
pub fn BufModule::from_config(config : @config.Config) -> BufModule {
  match config.get_raw_module("buf") {
    Some(table) => BufModule::from_toml_table(table)
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
