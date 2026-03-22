///|
pub struct TerraformModule {
  disabled : Bool
  format : String
  style : String
  symbol : String
  detect_files : Array[String]
  detect_folders : Array[String]
  detect_extensions : Array[String]
}

///|
pub fn TerraformModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "terraform",
  ),
) -> TerraformModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    symbol: config.get_prop("symbol", default="💠 "),
    detect_files: [],
    detect_folders: [".terraform"],
    detect_extensions: [".tf", ".tfplan", ".tfstate"],
  }
}

///|
pub fn TerraformModule::from_config(config : @config.Config) -> TerraformModule {
  TerraformModule::new(config=config.get_module("terraform"))
}

///|
pub impl @ms.PromptModule for TerraformModule with name(_self) -> String {
  "terraform"
}

///|
pub impl @ms.PromptModule for TerraformModule with is_async(_self) -> Bool {
  false
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
  let mut s = output
  let prefixes = ["Terraform v", "OpenTofu v", "Terraform ", "OpenTofu "]

  for prefix in prefixes {
    if s.has_prefix(prefix) {
      s = s[prefix.length():].to_string()
      break
    }
  }

  let parts = s.split(" ").collect()
  if parts.length() >= 1 {
    @exec.strip_v_prefix(parts[0].to_string())
  } else {
    ""
  }
}
