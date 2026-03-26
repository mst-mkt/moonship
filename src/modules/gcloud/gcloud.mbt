///|
pub struct GcloudModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
  region_aliases : Map[String, String]
  project_aliases : Map[String, String]
  detect_env_vars : Array[String]
}

///|
pub fn GcloudModule::default() -> GcloudModule {
  {
    disabled: false,
    async_render: false,
    format: "on [$symbol$account(@$domain)(\\($region\\))]($style) ",
    style: "bold blue",
    symbol: "☁️  ",
    region_aliases: {},
    project_aliases: {},
    detect_env_vars: [],
  }
}

///|
pub fn GcloudModule::from_table(table : @config.ModuleTable) -> GcloudModule {
  let d = GcloudModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    symbol: table.get_string("symbol").unwrap_or(d.symbol),
    region_aliases: table.get_string_map("region_aliases"),
    project_aliases: table.get_string_map("project_aliases"),
    detect_env_vars: table
    .get_string_array("detect_env_vars")
    .unwrap_or(d.detect_env_vars),
  }
}

///|
pub fn GcloudModule::from_config(config : @config.Config) -> GcloudModule {
  match config.get_raw_module("gcloud") {
    Some(table) => GcloudModule::from_table(table)
    None => GcloudModule::default()
  }
}

///|
pub impl @ms.PromptModule for GcloudModule with name(_self) -> String {
  "gcloud"
}

///|
pub impl @ms.PromptModule for GcloudModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for GcloudModule with execute(
  self,
  ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let gcloud_config = read_gcloud_config(ctx.home_dir)
  let account = get_value(
    "CLOUDSDK_CORE_ACCOUNT", gcloud_config, "core", "account",
  )
  let project = get_value(
    "CLOUDSDK_CORE_PROJECT", gcloud_config, "core", "project",
  )
  let region = get_value(
    "CLOUDSDK_COMPUTE_REGION", gcloud_config, "compute", "region",
  )

  guard not(account.is_empty()) || not(project.is_empty()) else {
    return Skipped("no gcloud config detected")
  }

  let vars : Map[String, String] = {
    "symbol": self.symbol,
    "style": self.style,
  }

  if not(account.is_empty()) {
    match account.find("@") {
      Some(idx) => {
        vars["account"] = account[:idx].to_string()
        vars["domain"] = account[idx + 1:].to_string()
      }
      None => vars["account"] = account
    }
  }

  if not(project.is_empty()) {
    vars["project"] = self.project_aliases.get(project).unwrap_or(project)
  }

  if not(region.is_empty()) {
    vars["region"] = self.region_aliases.get(region).unwrap_or(region)
  }

  let segments = @ms.format_string(
    self.format,
    vars,
    @terminal.Style::default(),
  )

  Output(@ms.ModuleOutput::new(segments))
}

///|
fn get_value(
  env_var : String,
  config : String,
  section : String,
  key : String,
) -> String {
  let env = @sys.get_env_var(env_var).unwrap_or("")
  if not(env.is_empty()) {
    return env
  }

  get_ini_value(config, section, key)
}

///|
fn read_gcloud_config(home_dir : String) -> String {
  let config_dir = @sys.get_env_var("CLOUDSDK_CONFIG").unwrap_or("")
  let base = if not(config_dir.is_empty()) {
    config_dir
  } else if not(home_dir.is_empty()) {
    "\{home_dir}/.config/gcloud"
  } else {
    return ""
  }

  let active_name = @fs.read_file_to_string("\{base}/active_config") catch {
    _ => "default"
  }

  let name = active_name.split("\n").map(fn(s) { s.to_string() }).collect()
  let raw_name = if name.length() > 0 { name[0] } else { "default" }

  let config_name = trim_whitespace(raw_name)
  let config_name_trimmed = if config_name.is_empty() {
    "default"
  } else {
    config_name
  }

  @fs.read_file_to_string(
    "\{base}/configurations/config_\{config_name_trimmed}",
  ) catch {
    _ => ""
  }
}

///|
fn get_ini_value(content : String, section : String, key : String) -> String {
  let section_header = "[\{section}]"

  content
  .split("\n")
  .fold(init=("", false), fn(acc, line) {
    let s = line.to_string()
    let (result, in_section) = acc

    if not(result.is_empty()) {
      acc
    } else if s.has_prefix("[") {
      ("", s == section_header)
    } else if in_section {
      match s.find("=") {
        Some(eq_idx) => {
          let k = trim_whitespace(s[:eq_idx].to_string())
          if k == key {
            (trim_whitespace(s[eq_idx + 1:].to_string()), true)
          } else {
            acc
          }
        }
        None => acc
      }
    } else {
      acc
    }
  }).0
}

///|
fn trim_whitespace(s : String) -> String {
  s.trim(chars=" \t\r\n").to_string()
}

///|
pub fn GcloudModule::schema() -> @config.ModuleSchema {
  let d = GcloudModule::default()
  {
    name: "gcloud",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      { name: "symbol", field_type: @config.FString, default_value: d.symbol },
    ],
  }
}
