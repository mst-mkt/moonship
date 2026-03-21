///|
pub struct HostnameModule {
  disabled : Bool
  format : String
  style : String
  ssh_only : Bool
  trim_at : String
  ssh_symbol : String
}

///|
pub fn HostnameModule::new(
  config? : @config.ModuleConfig = @config.Config::default().get_module(
    "hostname",
  ),
) -> HostnameModule {
  {
    disabled: config.disabled,
    format: config.format,
    style: config.style,
    ssh_only: config.get_prop("ssh_only", default="true") == "true",
    trim_at: config.get_prop("trim_at", default="."),
    ssh_symbol: config.get_prop("ssh_symbol", default="🌐 "),
  }
}

///|
pub fn HostnameModule::from_config(config : @config.Config) -> HostnameModule {
  HostnameModule::new(config=config.get_module("hostname"))
}

///|
pub impl @ms.PromptModule for HostnameModule with name(_self) -> String {
  "hostname"
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

  let raw = @sys.get_env_var("HOSTNAME").unwrap_or("")
  guard not(raw.is_empty()) else { return Skipped("HOSTNAME not set") }

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
