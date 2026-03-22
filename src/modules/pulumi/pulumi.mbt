///|
pub struct PulumiModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn PulumiModule::default() -> PulumiModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($username@)$stack]($style) ",
    style: "bold 5",
    symbol: " ",
    detect_files: ["Pulumi.yaml", "Pulumi.yml"],
    detect_extensions: [],
  }
}

///|
pub fn PulumiModule::from_toml_table(
  table : @config.ModuleTable,
) -> PulumiModule {
  let d = PulumiModule::default()
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
pub fn PulumiModule::from_config(config : @config.Config) -> PulumiModule {
  match config.get_raw_module("pulumi") {
    Some(table) => PulumiModule::from_toml_table(table)
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
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
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
    vars["version"] = @exec.add_v_prefix(@exec.strip_v_prefix(version))
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
    ],
  }
}
