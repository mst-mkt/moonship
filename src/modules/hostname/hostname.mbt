///|
pub struct HostnameModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  ssh_only : Bool
  trim_at : String
  ssh_symbol : String
  detect_env_vars : Array[String]
  aliases : Map[String, String]
}

///|
pub fn HostnameModule::default() -> HostnameModule {
  {
    disabled: false,
    async_render: false,
    format: "[$ssh_symbol$hostname]($style) in ",
    style: "green dimmed bold",
    ssh_only: true,
    trim_at: ".",
    ssh_symbol: "🌐 ",
    detect_env_vars: [],
    aliases: {},
  }
}

///|
pub fn HostnameModule::from_table(
  table : @config.ModuleTable,
) -> HostnameModule {
  let d = HostnameModule::default()
  {
    disabled: table.get_bool("disabled").unwrap_or(d.disabled),
    async_render: table.get_bool("async").unwrap_or(d.async_render),
    format: table.get_string("format").unwrap_or(d.format),
    style: table.get_string("style").unwrap_or(d.style),
    ssh_only: table.get_bool("ssh_only").unwrap_or(d.ssh_only),
    trim_at: table.get_string("trim_at").unwrap_or(d.trim_at),
    ssh_symbol: table.get_string("ssh_symbol").unwrap_or(d.ssh_symbol),
    detect_env_vars: table
    .get_string_array("detect_env_vars")
    .unwrap_or(d.detect_env_vars),
    aliases: table.get_string_map("aliases"),
  }
}

///|
pub fn HostnameModule::from_config(config : @config.Config) -> HostnameModule {
  match config.get_raw_module("hostname") {
    Some(table) => HostnameModule::from_table(table)
    None => HostnameModule::default()
  }
}

///|
pub impl @ms.PromptModule for HostnameModule with name(_self) -> String {
  "hostname"
}

///|
pub impl @ms.PromptModule for HostnameModule with is_async(self) -> Bool {
  self.async_render
}

///|
pub impl @ms.PromptModule for HostnameModule with execute(
  self,
  _ctx : @context.Context,
) -> @ms.ModuleResult {
  guard not(self.disabled) else { return Disabled }

  let is_ssh = @exec.is_ssh_session()
  let env_detected = self.detect_env_vars.iter().any(fn(env_name) {
    not(@sys.get_env_var(env_name).unwrap_or("").is_empty())
  })

  guard not(self.ssh_only) || is_ssh || env_detected else {
    return Skipped("not in SSH session")
  }

  let raw = match @sys.get_env_var("HOSTNAME") {
    Some(h) if not(h.is_empty()) => h
    _ => {
      let h = @exec.exec_cmd("hostname", [])
      guard not(h.is_empty()) else { return Skipped("hostname not available") }
      h
    }
  }

  let trimmed = trim_hostname(raw, self.trim_at)
  let hostname = self.aliases.get(trimmed).unwrap_or(trimmed)

  let vars : Map[String, String] = {
    "hostname": hostname,
    "ssh_symbol": if is_ssh { self.ssh_symbol } else { "" },
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
fn trim_hostname(raw : String, trim_at : String) -> String {
  if trim_at.is_empty() {
    return raw
  }

  match raw.split(trim_at).collect() {
    [first, ..] => first.to_string()
    _ => raw
  }
}

///|
pub fn HostnameModule::schema() -> @config.ModuleSchema {
  let d = HostnameModule::default()
  {
    name: "hostname",
    fields: [
      {
        name: "disabled",
        field_type: @config.FBool,
        default_value: d.disabled.to_string(),
      },
      { name: "format", field_type: @config.FString, default_value: d.format },
      { name: "style", field_type: @config.FString, default_value: d.style },
      {
        name: "ssh_only",
        field_type: @config.FBool,
        default_value: d.ssh_only.to_string(),
      },
      { name: "trim_at", field_type: @config.FString, default_value: d.trim_at },
      {
        name: "ssh_symbol",
        field_type: @config.FString,
        default_value: d.ssh_symbol,
      },
      {
        name: "detect_env_vars",
        field_type: @config.FStringArray,
        default_value: d.detect_env_vars.join(", "),
      },
    ],
  }
}
