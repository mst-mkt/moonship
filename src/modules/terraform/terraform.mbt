///|
pub struct TerraformModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_folders : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn TerraformModule::default() -> TerraformModule {
  {
    disabled: false,
    async_render: false,
    format: "via [$symbol$workspace]($style) ",
    style: "bold 105",
    symbol: "💠 ",
    detect_files: [],
    detect_folders: [".terraform"],
    detect_extensions: [".tf", ".tfplan", ".tfstate"],
  }
}

///|
pub fn TerraformModule::from_table(
  table : @config.ModuleTable,
) -> TerraformModule {
  let d = TerraformModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    detect_files: table
    .get_string_array("detect_files")
    .unwrap_or(d.detect_files),
    detect_folders: table
    .get_string_array("detect_folders")
    .unwrap_or(d.detect_folders),
    detect_extensions: table
    .get_string_array("detect_extensions")
    .unwrap_or(d.detect_extensions),
  }
}

///|
pub fn TerraformModule::from_config(config : @config.Config) -> TerraformModule {
  match config.get_raw_module("terraform") {
    Some(table) => TerraformModule::from_table(table)
    None => TerraformModule::default()
  }
}

///|
pub impl @ms.PromptModule for TerraformModule with name(_self) -> String {
  "terraform"
}

///|
pub impl @ms.PromptModule for TerraformModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for TerraformModule with execute(
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
    return Skipped("no Terraform project detected")
  }

  let vars : Map[String, String] = {
    "symbol": self.symbol,
    "style": self.style,
  }

  let tf_env = @sys.get_env_var("TF_WORKSPACE").unwrap_or("")
  if not(tf_env.is_empty()) {
    vars["workspace"] = tf_env
  } else {
    let env_path = ctx.cwd + "/.terraform/environment"
    let workspace = @fs.read_file_to_string(env_path) catch { _ => "default" }
    vars["workspace"] = if workspace.is_empty() { "default" } else { workspace }
  }

  let version_output = @exec.try_commands([
    ("terraform", "version"),
    ("tofu", "version"),
  ])
  if not(version_output.is_empty()) {
    vars["version"] = @exec.add_v_prefix(
      parse_terraform_version(version_output),
    )
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn parse_terraform_version(output : String) -> String {
  let s = ["Terraform v", "OpenTofu v", "Terraform ", "OpenTofu "]
    .iter()
    .find_first(fn(prefix) { output.has_prefix(prefix) })
    .map(fn(prefix) { output[prefix.length():].to_string() })
    .unwrap_or(output)

  let parts = s.split(" ").map(fn(p) { p.to_string() }).collect()
  if parts.length() >= 1 {
    @exec.strip_v_prefix(parts[0])
  } else {
    ""
  }
}

///|
pub fn TerraformModule::schema() -> @config.ModuleSchema {
  let d = TerraformModule::default()
  {
    name: "terraform",
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
        name: "detect_folders",
        field_type: @config.FStringArray,
        default_value: d.detect_folders.join(", "),
      },
      {
        name: "detect_extensions",
        field_type: @config.FStringArray,
        default_value: d.detect_extensions.join(", "),
      },
    ],
  }
}
