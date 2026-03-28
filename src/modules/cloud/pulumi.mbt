///|
pub struct PulumiModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  search_upwards : Bool
  version_format : String
  detect_files : Array[String]
  detect_extensions : Array[String]
  detect_folders : Array[String]
}

///|
pub fn PulumiModule::default() -> PulumiModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($username@)$stack]($style) ",
    style: "bold 5",
    symbol: " ",
    search_upwards: true,
    version_format: "v${raw}",
    detect_files: ["Pulumi.yaml", "Pulumi.yml"],
    detect_extensions: [],
    detect_folders: [],
  }
}

///|
pub fn PulumiModule::from_table(table : @config.ModuleTable) -> PulumiModule {
  let d = PulumiModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    search_upwards: table.get_bool("search_upwards").unwrap_or(d.search_upwards),
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
pub fn PulumiModule::from_config(config : @config.Config) -> PulumiModule {
  match config.get_raw_module("pulumi") {
    Some(table) => PulumiModule::from_table(table)
    None => PulumiModule::default()
  }
}

///|
pub impl @ms.PromptModule for PulumiModule with name(_self) -> String {
  "pulumi"
}

///|
pub impl @ms.PromptModule for PulumiModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for PulumiModule with execute(
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
    return Skipped("no Pulumi project detected")
  }

  let stack_output = @exec.exec_cmd("pulumi", [
    "stack", "--non-interactive", "--show-name",
  ])
  let vars : Map[String, String] = {
    "symbol": self.symbol,
    "style": self.style,
  }

  if not(stack_output.is_empty()) {
    vars["stack"] = stack_output
  }

  let version = @exec.exec_cmd("pulumi", ["version"])
  if not(version.is_empty()) {
    vars["version"] = @exec.format_version(version, self.version_format)
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
pub fn PulumiModule::schema() -> @config.ModuleSchema {
  let d = PulumiModule::default()
  {
    name: "pulumi",
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
        name: "search_upwards",
        field_type: @config.FBool,
        default_value: d.search_upwards.to_string(),
      },
      {
        name: "version_format",
        field_type: @config.FString,
        default_value: d.version_format,
      },
    ],
  }
}
