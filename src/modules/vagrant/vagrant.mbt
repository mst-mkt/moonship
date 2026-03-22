///|
pub struct VagrantModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn VagrantModule::default() -> VagrantModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol($version )]($style)",
    style: "cyan bold",
    symbol: "⍱ ",
    detect_files: ["Vagrantfile"],
    detect_extensions: [],
  }
}

///|
pub fn VagrantModule::from_toml_table(
  table : @config.ModuleTable,
) -> VagrantModule {
  let d = VagrantModule::default()
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
pub fn VagrantModule::from_config(config : @config.Config) -> VagrantModule {
  match config.get_raw_module("vagrant") {
    Some(table) => VagrantModule::from_toml_table(table)
    None => VagrantModule::default()
  }
}

///|
pub impl @ms.PromptModule for VagrantModule with name(_self) -> String {
  "vagrant"
}

///|
pub impl @ms.PromptModule for VagrantModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for VagrantModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }
  guard @exec.detect_project(ctx.cwd, self.detect_files, self.detect_extensions) else {
    return Skipped("no Vagrant project detected")
  }

  let output = @exec.exec_cmd("vagrant", ["--version"])
  guard not(output.is_empty()) else { return Skipped("vagrant not found") }

  let parts = output.split(" ").collect()
  guard parts.length() >= 2 else {
    return Skipped("could not parse vagrant version")
  }

  let version = parts[1].to_string()
  guard not(version.is_empty()) else {
    return Skipped("could not parse vagrant version")
  }

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
pub fn VagrantModule::schema() -> @config.ModuleSchema {
  let d = VagrantModule::default()
  {
    name: "vagrant",
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
