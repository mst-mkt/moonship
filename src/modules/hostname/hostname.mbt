///|
pub struct HostnameModule {
  disabled : Bool
  async_render : Bool
  format : String
  style : String
  ssh_only : Bool
  trim_at : String
  ssh_symbol : String
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
  }
}

///|
pub fn HostnameModule::from_toml_table(
  table : @config.ModuleTable,
) -> HostnameModule {
  let d = HostnameModule::default()
  {
    disabled: @config.get_toml_bool(table, "disabled").unwrap_or(d.disabled),
    async_render: @config.get_toml_bool(table, "async").unwrap_or(
      d.async_render,
    ),
    format: @config.get_toml_string(table, "format").unwrap_or(d.format),
    style: @config.get_toml_string(table, "style").unwrap_or(d.style),
    ssh_only: @config.get_toml_bool(table, "ssh_only").unwrap_or(d.ssh_only),
    trim_at: @config.get_toml_string(table, "trim_at").unwrap_or(d.trim_at),
    ssh_symbol: @config.get_toml_string(table, "ssh_symbol").unwrap_or(
      d.ssh_symbol,
    ),
  }
}

///|
pub fn HostnameModule::from_config(config : @config.Config) -> HostnameModule {
  match config.get_raw_module("hostname") {
    Some(table) => HostnameModule::from_toml_table(table)
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

  let is_ssh = not(@sys.get_env_var("SSH_CONNECTION").unwrap_or("").is_empty())
  guard not(self.ssh_only) || is_ssh else {
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

  let hostname = trim_hostname(raw, self.trim_at)

  let vars : Map[String, String] = { "hostname": hostname, "style": self.style }
  if is_ssh {
    vars["ssh_symbol"] = self.ssh_symbol
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
