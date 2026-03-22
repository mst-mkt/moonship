///|
pub struct GcloudModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  symbol : String
}

///|
pub fn GcloudModule::default() -> GcloudModule {
  {
    disabled: false,
    async_render: false,
    format: "on [$symbol$account(@$domain)(\\($region\\))]($style) ",
    style: "bold blue",
    symbol: "☁️  ",
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
    vars["project"] = project
  }

  if not(region.is_empty()) {
    vars["region"] = region
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
    home_dir + "/.config/gcloud"
  } else {
    return ""
  }

  let active_name = @fs.read_file_to_string(base + "/active_config") catch {
    _ => "default"
  }

  let name = active_name.split("\n").collect()
  let raw_name = if name.length() > 0 { name[0].to_string() } else { "default" }

  let config_name = trim_whitespace(raw_name)
  let config_name_trimmed = if config_name.is_empty() {
    "default"
  } else {
    config_name
  }

  @fs.read_file_to_string(
    base + "/configurations/config_" + config_name_trimmed,
  ) catch {
    _ => ""
  }
}

///|
fn get_ini_value(content : String, section : String, key : String) -> String {
  let lines = content.split("\n").collect()
  let section_header = "[" + section + "]"
  let mut in_section = false

  for line in lines {
    let s = line.to_string()

    if s.has_prefix("[") {
      in_section = s == section_header
      continue
    }

    if in_section {
      match s.find("=") {
        Some(eq_idx) => {
          let k = trim_whitespace(s[:eq_idx].to_string())
          if k == key {
            return trim_whitespace(s[eq_idx + 1:].to_string())
          }
        }
        None => ()
      }
    }
  }

  ""
}

///|
fn trim_whitespace(s : String) -> String {
  let mut start = 0
  let mut end = s.length()

  while start < end {
    let c = s[start].unsafe_to_char()
    if c == ' ' || c == '\t' || c == '\r' || c == '\n' {
      start += 1
    } else {
      break
    }
  }

  while end > start {
    let c = s[end - 1].unsafe_to_char()
    if c == ' ' || c == '\t' || c == '\r' || c == '\n' {
      end -= 1
    } else {
      break
    }
  }

  s[start:end].to_string()
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
